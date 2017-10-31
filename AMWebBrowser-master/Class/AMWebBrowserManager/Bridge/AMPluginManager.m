//
//  AMPluginManager.m
//  AMWebBrowser
//
//  Created by AndyMu on 2017/8/19.
//  Copyright © 2017年 AndyMu. All rights reserved.
//

/**
 native 和 js 定义的交互数据格式
 
 {"backRequire":true,"backMethod":"customFunction","messageId":001,"messageBody":{}}
 @param backRequire  是否需要回调js
 @param backMethod   回调对应的JS方法名(参数格式为json字符串，需要把messageId传回去，区分是哪个方法回调)
 @param messageId    传给native的数据id
 @param messageBody  传给native的数据(格式为json字符串)
 
 具体的传参和回调数据格式，可以指定符合自己项目需求的，只要native和js沟通统一就好
 ————————————————————————————————————————————————————————————————————————————————————————————————————
 js 端方法调用
 WKWebView 原生支持的方法，UIWebView 做兼容
 window.webkit.messageHandlers.<name>.postMessage(<messageBody>)
 
 */


#ifdef DEBUG
#   define DLog(fmt, ...) NSLog((@"%s [Line %d] " fmt), __PRETTY_FUNCTION__, __LINE__, ##__VA_ARGS__);
#else
#   define DLog(...)
#endif


#import "AMPluginManager.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import <WebKit/WebKit.h>
#import "AMWebBrowserViewController.h"
#import "AMSharePlugin.h"

static NSString * const kJSContextPath   = @"documentView.webView.mainFrame.javaScriptContext";
static NSString * const kMessageHandlers = @"messageHandlers";
static NSString * const kPostMessage     = @"postMessage";
static NSString * const kJSContextKey    = @"webkit";

static NSString * const kBackRequire     = @"backRequire";
static NSString * const kBackMethod      = @"backMethod";
static NSString * const kMessageId       = @"messageId";
static NSString * const kMessageBody     = @"messageBody";

@interface AMPluginManager()<WKScriptMessageHandler>

@property (nonatomic, strong)AMWebBrowserViewController *WebVC;
@property (nonatomic, strong)NSMutableDictionary *plugins;
@property (nonatomic, weak)JSContext *jsContext;
@property (nonatomic, strong)NSMutableDictionary *messageHandlers;
@property (nonatomic, strong)NSMutableDictionary * fakeJSValue;

@end

@implementation AMPluginManager

#pragma mark - Instantiation

- (instancetype)init {
    NSAssert(NO, @"%s should use initWithWebVC instantiation", __func__);
    return [self initWithWebVC:nil];
}


/**
 指定初始化函数
 */
- (instancetype)initWithWebVC:(AMWebBrowserViewController *)webVC {
    self = [super init];
    if (self) {
        self.WebVC = webVC;
        self.plugins = [NSMutableDictionary dictionaryWithCapacity:0];
        if (self.WebVC.uiWebView) {
            self.messageHandlers = [NSMutableDictionary dictionaryWithCapacity:0];
        }
    }
    return self;
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    id<AMBridgeProtocol> plugin = [_plugins objectForKey:message.name];
    if (plugin) {
        [self plugin:plugin messageBody:message.body];
    }
}

#pragma mark - DataHandle

/**
 native处理JS端传的数据
 */
- (void)plugin:(id<AMBridgeProtocol>)plugin messageBody:(id)messageBody{
    if ([messageBody isKindOfClass:[NSString class]]) {
        NSDictionary *dict = [self jsonStrngToObject:messageBody];
        if ([plugin respondsToSelector:@selector(browser:didReceivejavaScriptMessage:)]) {
            [plugin browser:self.WebVC didReceivejavaScriptMessage:dict[kMessageBody]];
        }
        if ([dict[kBackRequire] boolValue]) {
            if ([plugin respondsToSelector:@selector(callBackjavaScript)]) {
                NSMutableDictionary * backParam = [[NSMutableDictionary alloc]initWithCapacity:0];
                [backParam setDictionary:[plugin callBackjavaScript]];
                [backParam setValue:dict[kMessageId] forKey:kMessageId];
                
                NSString *paramString = [self objectToJsonStrng:backParam];
                NSString *backMethod = dict[kBackMethod];
                
                [self evaluateJavaScriptMethod:backMethod param:paramString];
            }
        }
    }
    
}

/**
 native回调JS方法
 */
-(void)evaluateJavaScriptMethod:(NSString *)method param:(NSString *)paramStr {
    
    NSString *jsString = [NSString stringWithFormat:@"%@('%@')",method,paramStr];
    if (self.WebVC.wkWebView) {
        [self.WebVC.wkWebView evaluateJavaScript:jsString completionHandler:^(id _Nullable result, NSError * _Nullable error) {
        }];
    }else if (self.WebVC.uiWebView){
        [self.WebVC.uiWebView stringByEvaluatingJavaScriptFromString:jsString];
    }
    
}

#pragma mark - Plugin

- (void)addDefaultPlugins{
    //初始化plugin
    for (id<AMBridgeProtocol> plugin in _pluginDatas) {
        [self addPlugin:plugin];
    }
    
    if (self.WebVC.uiWebView) {
        JSContext *jsContext = self.jsContext;
        jsContext[kJSContextKey] = self.fakeJSValue;
    }
}

- (void)addPlugin:(id<AMBridgeProtocol>)plugin {
    NSString * JSFunctionName = nil;
    if ([plugin respondsToSelector:@selector(javaScriptFunctionName)]) {
        JSFunctionName = [plugin javaScriptFunctionName];
    }
    if (!JSFunctionName || [_plugins objectForKey:JSFunctionName]) { return; }
    [_plugins setValue:plugin forKey:JSFunctionName];
    
    if (self.WebVC.wkWebView) {
        [self.WebVC.wkWebView.configuration.userContentController addScriptMessageHandler:self name:JSFunctionName];
    }else if (self.WebVC.uiWebView){
        if (![_messageHandlers objectForKey:JSFunctionName]) {
            __weak typeof(self) weakSelf  = self;
            [_messageHandlers setValue:@{kPostMessage:^(id data) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    __strong typeof(weakSelf) strongSelf = weakSelf;
                    [strongSelf plugin:plugin messageBody:data];
                });
            }} forKey:JSFunctionName];
        }
    }
}

- (id<AMBridgeProtocol>)getPlugin:(NSString *)name {
    return [_plugins objectForKey:name];
}

#pragma mark - Getters & Setters

- (JSContext *)jsContext {
    return [self.WebVC.uiWebView valueForKeyPath:kJSContextPath];
}

- (NSMutableDictionary *)fakeJSValue {
    if (!_fakeJSValue) {
        _fakeJSValue = @{kMessageHandlers: _messageHandlers}.mutableCopy;
    }
    return _fakeJSValue;
}

#pragma mark - JSON Serialization

-(id)jsonStrngToObject:(NSString *)jsonStr {
    NSData * jsonData = [jsonStr dataUsingEncoding:NSUTF8StringEncoding];
    id obj =  [NSJSONSerialization JSONObjectWithData:jsonData options:0 error:nil];
    return obj;
}

-(NSString *)objectToJsonStrng:(id)obj {
    NSData * data = [NSJSONSerialization dataWithJSONObject:obj options:0 error:nil];
    NSString * jsonStr = [[NSString alloc]initWithData:data encoding:NSUTF8StringEncoding];
    return jsonStr;
}

@end

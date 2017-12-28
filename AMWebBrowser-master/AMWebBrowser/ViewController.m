//
//  ViewController.m
//  AMWebBrowser
//
//  Created by AndyMu on 2017/8/15.
//  Copyright © 2017年 AndyMu. All rights reserved.
//

#import "ViewController.h"
#import "AMWebBrowserViewController.h"
#import <AddressBook/AddressBook.h>
#import "AMRefreshView.h"
#import "AMSharePlugin.h"

@interface ViewController ()
@property (nonatomic,strong)WKWebView *wkWebView;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

// 注入获取app版本号的js代码
- (NSString *)getVersionInjectionCode {
    
    NSString *injectionCode = @"function goToTest2(name) { window.webkit.messageHandlers.shareInfo.postMessage(name); } function goToTest3(name) { window.webkit.messageHandlers.shareInfo.postMessage(name); }";
    
    return injectionCode;
}

- (IBAction)push:(UIButton *)sender {
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSURL *baseURL = [NSURL fileURLWithPath:path];
    
    WKUserContentController *userContentController = [[WKUserContentController alloc] init];
    // 注入获取app版本号的js代码
    WKUserScript *script = [[WKUserScript alloc] initWithSource:[self getVersionInjectionCode] injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:NO];
    [userContentController addUserScript:script];
    WKWebViewConfiguration *webViewConfiguration = [[WKWebViewConfiguration alloc] init];
    webViewConfiguration.userContentController = userContentController;
    
    AMWebBrowserViewController * webBrowser = [AMWebBrowserViewController webBrowserWithConfiguration:webViewConfiguration];
    
    //自定义返回按钮 和 后退按钮
    webBrowser.backButtonImage = [UIImage imageNamed:@"nav_btn_back_default"];
    webBrowser.closeButtonImage = [UIImage imageNamed:@"nav_icon_close"];
    
    //自定义加载失败页面
    AMRefreshView * refreshView = [[AMRefreshView alloc]init];
    refreshView.block = ^{
        [webBrowser loadURL:webBrowser.failUrl];
    };
    webBrowser.refreshView = refreshView;
    
    //加载plugins
    webBrowser.plugins = @[[[AMSharePlugin alloc]init]];
    
    NSString * htmlPath = [[NSBundle mainBundle] pathForResource:@"test"
                                                          ofType:@"html"];
    NSString * htmlString = [NSString stringWithContentsOfFile:htmlPath
                                                      encoding:NSUTF8StringEncoding
                                                         error:nil];
    [webBrowser loadHTMLString:htmlString baseURl:baseURL];
    

    [self.navigationController pushViewController:webBrowser animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end

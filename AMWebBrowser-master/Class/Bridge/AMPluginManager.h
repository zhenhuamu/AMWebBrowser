//
//  AMPluginManager.h
//  AMWebBrowser
//
//  Created by AndyMu on 2017/8/19.
//  Copyright © 2017年 AndyMu. All rights reserved.
//

#import <Foundation/Foundation.h>
@class AMWebBrowserViewController;

NS_ASSUME_NONNULL_BEGIN

@protocol AMBridgeProtocol <NSObject>

@required

/**
 js调用native的方法名
 */
- (NSString *)javaScriptFunctionName;

@optional

/**
 native接收到的JS传过来的数据
 */
- (void)browser:(AMWebBrowserViewController *)browser didReceivejavaScriptMessage:(NSDictionary *)message;

/**
 回调给JS的数据
 */
- (NSDictionary *)callBackjavaScript;

@end


@interface AMPluginManager : NSObject

/**
 指定初始化函数
 */
-(instancetype)initWithWebVC:(AMWebBrowserViewController *)webVC NS_DESIGNATED_INITIALIZER;

/**
 初始化plugins
 */
- (void)addDefaultPlugins;

@property (nonatomic, copy) NSArray<id<AMBridgeProtocol>> * pluginDatas;

@end

NS_ASSUME_NONNULL_END

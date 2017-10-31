//
//  AMBridgeProtocol.h
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

NS_ASSUME_NONNULL_END


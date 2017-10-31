//
//  AMSharePlugin.m
//  AMWebBrowser
//
//  Created by AndyMu on 2017/8/20.
//  Copyright © 2017年 AndyMu. All rights reserved.
//

#import "AMSharePlugin.h"

static NSString * const jsFunctionName = @"shareInfo";

@implementation AMSharePlugin

- (NSString *)javaScriptFunctionName {
    return jsFunctionName;
}

- (void)browser:(AMWebBrowserViewController *)browser didReceivejavaScriptMessage:(NSDictionary *)message {
    if (message) {
        NSLog(@"%@",message);
    }
}

- (NSDictionary *)callBackjavaScript {
    return @{@"stauts":@"success"};
}

@end

//
//  AMPluginManager.h
//  AMWebBrowser
//
//  Created by AndyMu on 2017/8/19.
//  Copyright © 2017年 AndyMu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AMBridgeProtocol.h"
@class AMWebBrowserViewController;


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

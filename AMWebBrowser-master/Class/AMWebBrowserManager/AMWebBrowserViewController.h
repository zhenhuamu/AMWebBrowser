//
//  AMWebBrowserViewController.h
//  AMWebBrowser
//
//  Created by AndyMu on 2017/8/15.
//  Copyright © 2017年 AndyMu. All rights reserved.
//  基于AMWebBrowserViewController的基础之上修改

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>
#import "AMBridgeProtocol.h"

@class AMWebBrowserViewController;

/*
 
 UINavigationController+AMWebBrowserWrapper category enables access to casted AMWebBrowserViewController when set as rootViewController of UINavigationController
 
 */
@interface UINavigationController (KINWebBrowser)

// Returns rootViewController casted as AMWebBrowserViewController
- (AMWebBrowserViewController *)rootWebBrowser;

@end

@protocol AMWebBrowserDelegate <NSObject>
@optional
- (void)webBrowser:(AMWebBrowserViewController *)webBrowser didStartLoadingURL:(NSURL *)URL;
- (void)webBrowser:(AMWebBrowserViewController *)webBrowser didFinishLoadingURL:(NSURL *)URL;
- (void)webBrowser:(AMWebBrowserViewController *)webBrowser didFailToLoadURL:(NSURL *)URL error:(NSError *)error;
- (void)webBrowserViewControllerWillDismiss:(AMWebBrowserViewController *)viewController;
@end

/*
 
 AMWebBrowserViewController is designed to be used inside of a UINavigationController.
 For convenience, two sets of static initializers are available.
 
 */
@interface AMWebBrowserViewController : UIViewController <WKNavigationDelegate, WKUIDelegate, UIWebViewDelegate>

#pragma mark - Public Properties

@property (nonatomic, weak) id<AMWebBrowserDelegate> delegate;

// The main and only UIProgressView
@property (nonatomic, strong) UIProgressView *progressView;

// The web views
// Depending on the version of iOS, one of these will be set
@property (nonatomic, strong) WKWebView *wkWebView;
@property (nonatomic, strong) UIWebView *uiWebView;

- (id)initWithConfiguration:(WKWebViewConfiguration *)configuration NS_AVAILABLE_IOS(8_0);

#pragma mark - Static Initializers

/*
 Initialize a basic AMWebBrowserViewController instance for push onto navigation stack
 
 Ideal for use with UINavigationController pushViewController:animated: or initWithRootViewController:
 
 Optionally specify AMWebBrowser options or WKWebConfiguration
 */

+ (AMWebBrowserViewController *)webBrowser;
+ (AMWebBrowserViewController *)webBrowserWithConfiguration:(WKWebViewConfiguration *)configuration NS_AVAILABLE_IOS(8_0);

/*
 Initialize a UINavigationController with a AMWebBrowserViewController for modal presentation.
 
 Ideal for use with presentViewController:animated:
 
 Optionally specify AMWebBrowser options or WKWebConfiguration
 */

+ (UINavigationController *)navigationControllerWithWebBrowser;
+ (UINavigationController *)navigationControllerWithWebBrowserWithConfiguration:(WKWebViewConfiguration *)configuration NS_AVAILABLE_IOS(8_0);

// UI相关
@property (nonatomic, strong) UIColor *tintColor;
@property (nonatomic, strong) UIColor *barTintColor;
@property (nonatomic, strong) UIImage *backButtonImage;
@property (nonatomic, strong) UIImage *closeButtonImage;
@property (nonatomic, strong) UIView  *refreshView;
@property (nonatomic, assign) BOOL showsURLInNavigationBar;
@property (nonatomic, assign) BOOL showsPageTitleInNavigationBar;

// 当前加载失败的URL
@property (nonatomic, strong) NSURL *failUrl;

// 遵循协议要和js交互的各个组件
@property (nonatomic, copy) NSArray<id<AMBridgeProtocol>> * plugins;

#pragma mark - Public Interface

// Load a NSURLURLRequest to web view
// Can be called any time after initialization
- (void)loadRequest:(NSURLRequest *)request;

// Load a NSURL to web view
// Can be called any time after initialization
- (void)loadURL:(NSURL *)URL;

// Loads a URL as NSString to web view
// Can be called any time after initialization
- (void)loadURLString:(NSString *)URLString;

// Loads an string containing HTML to web view
// Can be called any time after initialization
- (void)loadHTMLString:(NSString *)HTMLString;

- (void)loadHTMLString:(NSString *)HTMLString baseURl:(NSURL *)baseUrl;

@end

//
//  AMWebBrowserViewController.m
//  AMWebBrowser
//
//  Created by AndyMu on 2017/8/15.
//  Copyright © 2017年 AndyMu. All rights reserved.
//  基于AMWebBrowserViewController的基础之上修改

#import "AMWebBrowserViewController.h"
#import "AMPluginManager.h"

#ifdef NSFoundationVersionNumber_iOS_9_x_Max
#define AM_IS_IOS10_OR_GREATER (floor(NSFoundationVersionNumber) > NSFoundationVersionNumber_iOS_9_x_Max)
#else
#define AM_IS_IOS10_OR_GREATER NO
#endif

static void *AMWebBrowserContext = &AMWebBrowserContext;

@interface AMWebBrowserViewController ()

@property (nonatomic, assign) BOOL previousNavigationControllerToolbarHidden, previousNavigationControllerNavigationBarHidden;
@property (nonatomic, strong) NSTimer *fakeProgressTimer;
@property (nonatomic, assign) BOOL uiWebViewIsLoading;
@property (nonatomic, strong) NSURL *uiWebViewCurrentURL;
@property (nonatomic, strong) UIView *leftView;
@property (nonatomic, strong) UIButton *backButton;
@property (nonatomic, strong) UIButton *closeButton;
@property (nonatomic, strong) NSURL *currentUrl;

@property (nonatomic, strong) AMPluginManager *pluginManager;

@end

@implementation AMWebBrowserViewController

#pragma mark - Static Initializers

+ (AMWebBrowserViewController *)webBrowser {
    AMWebBrowserViewController *webBrowserViewController = [AMWebBrowserViewController webBrowserWithConfiguration:nil];
    return webBrowserViewController;
}

+ (AMWebBrowserViewController *)webBrowserWithConfiguration:(WKWebViewConfiguration *)configuration {
    AMWebBrowserViewController *webBrowserViewController = [[self alloc] initWithConfiguration:configuration];
    return webBrowserViewController;
}

+ (UINavigationController *)navigationControllerWithWebBrowser {
    AMWebBrowserViewController *webBrowserViewController = [[self alloc] initWithConfiguration:nil];
    return [AMWebBrowserViewController navigationControllerWithBrowser:webBrowserViewController];
}

+ (UINavigationController *)navigationControllerWithWebBrowserWithConfiguration:(WKWebViewConfiguration *)configuration {
    AMWebBrowserViewController *webBrowserViewController = [[self alloc] initWithConfiguration:configuration];
    return [AMWebBrowserViewController navigationControllerWithBrowser:webBrowserViewController];
}

+ (UINavigationController *)navigationControllerWithBrowser:(AMWebBrowserViewController *)webBrowser {
    UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:webBrowser action:@selector(doneButtonPressed:)];
    [webBrowser.navigationItem setRightBarButtonItem:doneButton];

    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:webBrowser];
    return navigationController;
}

#pragma mark - Initializers

- (id)init {
    return [self initWithConfiguration:nil];
}

- (id)initWithConfiguration:(WKWebViewConfiguration *)configuration {
    self = [super init];
    if (self) {
        if ([WKWebView class]) {
            if (configuration) {
                self.wkWebView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
            } else {
                self.wkWebView = [[WKWebView alloc] init];
            }
        } else {
            self.uiWebView = [[UIWebView alloc] init];
        }

        self.showsURLInNavigationBar = NO;
        self.showsPageTitleInNavigationBar = YES;
    }
    return self;
}

#pragma mark - View Lifecycle

- (void)viewDidLoad {
    [super viewDidLoad];

    // 初始化交互管理器
    AMPluginManager * aPluginManager = [[AMPluginManager alloc] initWithWebVC:self];
    aPluginManager.pluginDatas = _plugins;
    self.pluginManager = aPluginManager;
    
    self.previousNavigationControllerToolbarHidden = self.navigationController.toolbarHidden;
    self.previousNavigationControllerNavigationBarHidden = self.navigationController.navigationBarHidden;

    if (self.wkWebView) {
        [self.wkWebView setFrame:self.view.bounds];
        [self.wkWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.wkWebView setNavigationDelegate:self];
        [self.wkWebView setUIDelegate:self];
        [self.wkWebView setMultipleTouchEnabled:YES];
        [self.wkWebView setAutoresizesSubviews:YES];
        [self.wkWebView.scrollView setAlwaysBounceVertical:YES];
        [self.view addSubview:self.wkWebView];
        [self.wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:AMWebBrowserContext];
        
        [_pluginManager addDefaultPlugins];
        
    } else if (self.uiWebView) {
        [self.uiWebView setFrame:self.view.bounds];
        [self.uiWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [self.uiWebView setDelegate:self];
        [self.uiWebView setMultipleTouchEnabled:YES];
        [self.uiWebView setAutoresizesSubviews:YES];
        [self.uiWebView setScalesPageToFit:YES];
        [self.uiWebView.scrollView setAlwaysBounceVertical:YES];
        [self.view addSubview:self.uiWebView];
    }

    [self addBackButton];
    self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
    [self.progressView setTrackTintColor:[UIColor colorWithWhite:1.0f alpha:0.0f]];
    [self.progressView setFrame:CGRectMake(0, self.navigationController.navigationBar.frame.size.height - self.progressView.frame.size.height, self.view.frame.size.width, self.progressView.frame.size.height)];
    [self.progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];

    [self.navigationController setNavigationBarHidden:NO animated:YES];

    [self.navigationController.navigationBar addSubview:self.progressView];

    [self updateTitle];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];

    [self.navigationController setNavigationBarHidden:self.previousNavigationControllerNavigationBarHidden animated:animated];

    [self.navigationController setToolbarHidden:self.previousNavigationControllerToolbarHidden animated:animated];

    [self.uiWebView setDelegate:nil];
    [self.progressView removeFromSuperview];
}

#pragma mark - Public Interface

- (void)loadRequest:(NSURLRequest *)request {
    if (self.wkWebView) {
        [self.wkWebView loadRequest:request];
    } else if (self.uiWebView) {
        [self.uiWebView loadRequest:request];
    }
}

- (void)loadURL:(NSURL *)URL {
    [self loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)loadURLString:(NSString *)URLString {
    NSURL *URL = [NSURL URLWithString:URLString];
    [self loadURL:URL];
}

- (void)loadHTMLString:(NSString *)HTMLString {
    if (self.wkWebView) {
        [self.wkWebView loadHTMLString:HTMLString baseURL:nil];
    } else if (self.uiWebView) {
        [self.uiWebView loadHTMLString:HTMLString baseURL:nil];
    }
}

- (void)loadHTMLString:(NSString *)HTMLString baseURl:(NSURL *)baseUrl{
    if(self.wkWebView) {
        [self.wkWebView loadHTMLString:HTMLString baseURL:baseUrl];
    }
    else if(self.uiWebView) {
        [self.uiWebView loadHTMLString:HTMLString baseURL:baseUrl];
    }
}

- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    [self.progressView setTintColor:tintColor];
    [self.navigationController.navigationBar setTintColor:tintColor];
    [self.navigationController.toolbar setTintColor:tintColor];
}

- (void)setBarTintColor:(UIColor *)barTintColor {
    _barTintColor = barTintColor;
    [self.navigationController.navigationBar setBarTintColor:barTintColor];
    [self.navigationController.toolbar setBarTintColor:barTintColor];
}

- (void)checkWebViewCanGoBack{
    if (self.leftView.subviews.count >= 2) {
        return;
    }
    if (_uiWebView && [_uiWebView canGoBack]) {
        [self addCloseButton];
    } else if (_wkWebView && [_wkWebView canGoBack]) {
        [self addCloseButton];
    }
}

#pragma mark - UIWebViewDelegate

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    if (webView == self.uiWebView) {
            self.currentUrl = webView.request.URL;
        if (![self externalAppRequiredToOpenURL:request.URL]) {
            self.uiWebViewCurrentURL = request.URL;
            self.uiWebViewIsLoading = YES;
            [self updateTitle];

            [self fakeProgressViewStartLoading];

            if ([self.delegate respondsToSelector:@selector(webBrowser:didStartLoadingURL:)]) {
                [self.delegate webBrowser:self didStartLoadingURL:request.URL];
            }
            return YES;
        } else {
            if (![self externalAppRequiredToFileURL:request.URL]) {
                return YES;
            }
            [self launchExternalAppWithURL:request.URL];
            return NO;
        }
    }
    return NO;
}

- (void)webViewDidStartLoad:(UIWebView *)webView {
    if (webView == self.uiWebView) {
        [_pluginManager addDefaultPlugins];
    }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView {
    if (webView == self.uiWebView) {
        [self checkWebViewCanGoBack];
        if (!self.uiWebView.isLoading) {
            self.uiWebViewIsLoading = NO;
            [self updateTitle];

            [self fakeProgressBarStopLoading];
            
            if (_refreshView) {
                [_refreshView removeFromSuperview];
            }
        }

        if ([self.delegate respondsToSelector:@selector(webBrowser:didFinishLoadingURL:)]) {
            [self.delegate webBrowser:self didFinishLoadingURL:self.uiWebView.request.URL];
        }
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    if (webView == self.uiWebView) {
        if (!self.uiWebView.isLoading) {
            self.failUrl = _currentUrl;
            self.uiWebViewIsLoading = NO;
            [self updateTitle];

            [self fakeProgressBarStopLoading];
            if (_refreshView) {
                [self.refreshView setFrame:self.view.bounds];
                [self.uiWebView addSubview:self.refreshView];
            }
        }
        if ([self.delegate respondsToSelector:@selector(webBrowser:didFailToLoadURL:error:)]) {
            [self.delegate webBrowser:self didFailToLoadURL:self.uiWebView.request.URL error:error];
        }
    }
}

#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if (webView == self.wkWebView) {
        self.currentUrl = webView.URL;
        [self updateTitle];
        if ([self.delegate respondsToSelector:@selector(webBrowser:didStartLoadingURL:)]) {
            [self.delegate webBrowser:self didStartLoadingURL:self.wkWebView.URL];
        }
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (webView == self.wkWebView) {
        [self updateTitle];
        if (_refreshView) {
            [_refreshView removeFromSuperview];
        }
        if ([self.delegate respondsToSelector:@selector(webBrowser:didFinishLoadingURL:)]) {
            [self.delegate webBrowser:self didFinishLoadingURL:self.wkWebView.URL];
        }
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
                       withError:(NSError *)error {
    if (webView == self.wkWebView) {
        self.failUrl = _currentUrl;
        [self updateTitle];
        if (_refreshView) {
            [self.refreshView setFrame:self.view.bounds];
            [self.wkWebView addSubview:self.refreshView];
        }
        if ([self.delegate respondsToSelector:@selector(webBrowser:didFailToLoadURL:error:)]) {
            [self.delegate webBrowser:self didFailToLoadURL:self.wkWebView.URL error:error];
        }
    }
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
            withError:(NSError *)error {
    if (webView == self.wkWebView) {
        [self updateTitle];
        if ([self.delegate respondsToSelector:@selector(webBrowser:didFailToLoadURL:error:)]) {
            [self.delegate webBrowser:self didFailToLoadURL:self.wkWebView.URL error:error];
        }
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    if (webView == self.wkWebView) {
        [self checkWebViewCanGoBack];
        NSURL *URL = navigationAction.request.URL;
        if (![self externalAppRequiredToOpenURL:URL]) {
            if (!navigationAction.targetFrame) {
                [self loadURL:URL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        } else if ([[UIApplication sharedApplication] canOpenURL:URL]) {
            if ([self externalAppRequiredToFileURL:URL]) {
                [self launchExternalAppWithURL:URL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}

#pragma mark - Toolbar State

- (void)updateTitle {

    if (self.wkWebView.loading || self.uiWebViewIsLoading) {

        if (self.showsURLInNavigationBar) {
            NSString *URLString;
            if (self.wkWebView) {
                URLString = [self.wkWebView.URL absoluteString];
            } else if (self.uiWebView) {
                URLString = [self.uiWebViewCurrentURL absoluteString];
            }

            URLString = [URLString stringByReplacingOccurrencesOfString:@"http://" withString:@""];
            URLString = [URLString stringByReplacingOccurrencesOfString:@"https://" withString:@""];
            URLString = [URLString substringToIndex:[URLString length] - 1];
            self.navigationItem.title = URLString;
        }
    } else {
        if (self.showsPageTitleInNavigationBar) {
            if (self.wkWebView) {
                self.navigationItem.title = self.wkWebView.title;
            } else if (self.uiWebView) {
                self.navigationItem.title = [self.uiWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
            }
        }
    }

    self.tintColor = self.tintColor;
    self.barTintColor = self.barTintColor;
}

#pragma mark - LeftView


- (void)addBackButton{
    if (_backButtonImage) {
        [self.leftView addSubview:self.backButton];
        
        UIBarButtonItem *rightItem = [[UIBarButtonItem alloc] initWithCustomView:self.leftView];
        
        UIBarButtonItem *negativeSpacer = [[UIBarButtonItem alloc]
                                           initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace
                                           target:nil action:nil];
        negativeSpacer.width = -15;
        
        self.navigationItem.leftBarButtonItems = @[negativeSpacer,rightItem];
    }
}

- (void)addCloseButton{
    [self.leftView addSubview:self.closeButton];
}

- (UIView *)leftView{
    if (!_leftView) {
        _leftView = [[UIView alloc] init];
        _leftView.frame = CGRectMake(0, 0, 80, 40);
    }
    return _leftView;
}

- (UIButton *)backButton {
    if (!_backButton && _backButtonImage) {
        _backButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_backButton setImage:_backButtonImage forState:UIControlStateNormal];
        _backButton.frame = CGRectMake(0, 0, 40, 40);
        [_backButton addTarget:self action:@selector(backButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _backButton;
}

- (UIButton *)closeButton{
    if (!_closeButton && _closeButtonImage) {
        _closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _closeButton.frame = CGRectMake(40, 0, 40, 40);
        [_closeButton setImage:_closeButtonImage forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(closeButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _closeButton;
}

#pragma mark - Close Button Action

- (void)closeButtonPressed:(id)sender {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Done Button Action

- (void)doneButtonPressed:(id)sender {
    [self dismissAnimated:YES];
}

#pragma mark - UIButton Target Action Methods

- (void)backButtonPressed:(id)sender {

    if (self.wkWebView) {
        if ([self.wkWebView canGoBack]) {
            [self.wkWebView goBack];
        }else{
            [self closeButtonPressed:self.closeButton];
        }
    } else if (self.uiWebView) {
        if ([self.uiWebView canGoBack]) {
            [self.uiWebView goBack];
        }else{
            [self closeButtonPressed:self.closeButton];
        }
    }
    [self updateTitle];
}

- (void)forwardButtonPressed:(id)sender {
    if (self.wkWebView) {
        [self.wkWebView goForward];
    } else if (self.uiWebView) {
        [self.uiWebView goForward];
    }
    [self updateTitle];
}

- (void)refreshButtonPressed:(id)sender {
    if (self.wkWebView) {
        [self.wkWebView stopLoading];
        [self.wkWebView reload];
    } else if (self.uiWebView) {
        [self.uiWebView stopLoading];
        [self.uiWebView reload];
    }
}

- (void)stopButtonPressed:(id)sender {
    if (self.wkWebView) {
        [self.wkWebView stopLoading];
    } else if (self.uiWebView) {
        [self.uiWebView stopLoading];
    }
}

#pragma mark - Estimated Progress KVO (WKWebView)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];

        // Once complete, fade out UIProgressView
        if (self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f
                delay:0.3f
                options:UIViewAnimationOptionCurveEaseOut
                animations:^{
                    [self.progressView setAlpha:0.0f];
                }
                completion:^(BOOL finished) {
                    [self.progressView setProgress:0.0f animated:NO];
                }];
        }
    } else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Fake Progress Bar Control (UIWebView)

- (void)fakeProgressViewStartLoading {
    [self.progressView setProgress:0.0f animated:NO];
    [self.progressView setAlpha:1.0f];

    if (!self.fakeProgressTimer) {
        self.fakeProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f / 60.0f target:self selector:@selector(fakeProgressTimerDidFire:) userInfo:nil repeats:YES];
    }
}

- (void)fakeProgressBarStopLoading {
    if (self.fakeProgressTimer) {
        [self.fakeProgressTimer invalidate];
    }

    if (self.progressView) {
        [self.progressView setProgress:1.0f animated:YES];
        [UIView animateWithDuration:0.3f
            delay:0.3f
            options:UIViewAnimationOptionCurveEaseOut
            animations:^{
                [self.progressView setAlpha:0.0f];
            }
            completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
    }
}

- (void)fakeProgressTimerDidFire:(id)sender {
    CGFloat increment = 0.005 / (self.progressView.progress + 0.2);
    if ([self.uiWebView isLoading]) {
        CGFloat progress = (self.progressView.progress < 0.75f) ? self.progressView.progress + increment : self.progressView.progress + 0.0005;
        if (self.progressView.progress < 0.95) {
            [self.progressView setProgress:progress animated:YES];
        }
    }
}

#pragma mark - External App Support

- (BOOL)externalAppRequiredToOpenURL:(NSURL *)URL {
    NSSet *validSchemes = [NSSet setWithArray:@[ @"http", @"https" ]];
    return ![validSchemes containsObject:URL.scheme];
}

- (BOOL)externalAppRequiredToFileURL:(NSURL *)URL {
    NSSet *validSchemes = [NSSet setWithArray:@[ @"file" ]];
    return ![validSchemes containsObject:URL.scheme];
}

- (void)launchExternalAppWithURL:(NSURL *)URL {
    if (AM_IS_IOS10_OR_GREATER) {
        [[UIApplication sharedApplication] openURL:URL
                                           options:@{ UIApplicationOpenURLOptionUniversalLinksOnly : @NO }
                                 completionHandler:^(BOOL success){
                                 }];
    } else {
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
        [[UIApplication sharedApplication] openURL:URL];
#pragma clang diagnostic pop
    }
}

#pragma mark - Dismiss

- (void)dismissAnimated:(BOOL)animated {
    if ([self.delegate respondsToSelector:@selector(webBrowserViewControllerWillDismiss:)]) {
        [self.delegate webBrowserViewControllerWillDismiss:self];
    }
    [self.navigationController dismissViewControllerAnimated:animated completion:nil];
}

#pragma mark - Interface Orientation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
    return UIInterfaceOrientationMaskAllButUpsideDown;
}

- (BOOL)shouldAutorotate {
    return YES;
}

#pragma mark - Dealloc

- (void)dealloc {
    [self.uiWebView setDelegate:nil];

    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
    if ([self isViewLoaded]) {
        [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    }
}

@end

@implementation UINavigationController (KINWebBrowser)

- (AMWebBrowserViewController *)rootWebBrowser {
    UIViewController *rootViewController = [self.viewControllers objectAtIndex:0];
    return (AMWebBrowserViewController *)rootViewController;
}

@end


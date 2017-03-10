//
//  BuyBitcoinViewController.m
//  Blockchain
//
//  Created by kevinwu on 1/27/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <stdio.h>
#import "BuyBitcoinViewController.h"
#import <WebKit/WebKit.h>
#import "NSString+NSString_EscapeQuotes.h"
#import "RootService.h"

@interface BuyBitcoinViewController () <WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic) WKWebView *webView;
@property (nonatomic) BOOL didInitiateTrade;
@property (nonatomic) BOOL isReady;
@property (nonatomic) NSString* queuedScript;
@end

NSString* funcWithArgs(NSString*, NSString*, NSString*, NSString*, NSString*);

@implementation BuyBitcoinViewController

- (id)init
{
    if (self = [super init]) {
        
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        WKUserContentController* userController = [[WKUserContentController alloc] init];
        
        [userController addScriptMessageHandler:self name:WEBKIT_HANDLER_BUY_COMPLETED];
        [userController addScriptMessageHandler:self name:WEBKIT_HANDLER_FRONTEND_INITIALIZED];
        
        configuration.userContentController = userController;
        
        self.webView = [[WKWebView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - DEFAULT_HEADER_HEIGHT) configuration:configuration];
        [self.view addSubview:self.webView];
        
        self.webView.navigationDelegate = self;
        self.webView.scrollView.scrollEnabled = NO;
        self.automaticallyAdjustsScrollViewInsets = NO;
        
        NSURL *login = [NSURL URLWithString:URL_BUY_WEBVIEW];
        NSURLRequest *request = [NSURLRequest requestWithURL:login cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval: 10.0];
        [self.webView loadRequest:request];
        
    }
    return self;
}

NSString* funcWithArgs(NSString* name, NSString* a1, NSString* a2, NSString* a3, NSString* a4)
{
    return [ NSString stringWithFormat:@"%@('%@','%@','%@','%@')", name, [a1 escapeStringForJS], [a2 escapeStringForJS], [a3 escapeStringForJS], [a4 escapeStringForJS] ];
}


- (void)loginWithGuid:(NSString *)guid sharedKey:(NSString *)sharedKey password:(NSString *)password
{
    NSString *script = funcWithArgs(@"activateMobileBuy", guid, sharedKey, password, nil);
    [self runScriptWhenReady:script];
}

- (void)loginWithJson:(NSString *)json externalJson:(NSString *)externalJson magicHash:(NSString *)magicHash password:(NSString *)password
{
    NSString *script = funcWithArgs(@"activateMobileBuyFromJson", json, externalJson, magicHash, password);
    [self runScriptWhenReady:script];
}

- (void)runScript:(NSString *)script
{
    [self.webView evaluateJavaScript:script completionHandler:^(id result, NSError * _Nullable error) {
        DLog(@"Ran script with result %@, error %@", result, error);
    }];
}

- (void)runScriptWhenReady:(NSString *)script
{
    if (self.isReady) {
        [self runScript:script];
        self.queuedScript = nil;
    } else {
        self.queuedScript = script;
    }
}

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message
{
    DLog(@"Received script message: '%@'", message.name);
    
    if ([message.name isEqual: WEBKIT_HANDLER_FRONTEND_INITIALIZED]) {
        self.isReady = YES;
        if (self.queuedScript != nil) {
            [self runScript:self.queuedScript];
        }
    }
    
    if ([message.name isEqual: WEBKIT_HANDLER_BUY_COMPLETED]) {
        self.didInitiateTrade = YES;
    }
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    if (self.didInitiateTrade) {
        [self.delegate watchPendingTrades];
    } else {
        [self.delegate fetchExchangeAccount];
    }
    [self runScript:@"teardown()"];
    self.didInitiateTrade = NO;
    self.isReady = NO;
}

@end

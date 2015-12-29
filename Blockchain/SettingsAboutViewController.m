//
//  SettingsAboutViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/15/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsAboutViewController.h"

@interface SettingsAboutViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
@property (nonatomic) UILongPressGestureRecognizer *longPressGesture;
@property (nonatomic) UIView *longPressGestureView;
@end

@implementation SettingsAboutViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.automaticallyAdjustsScrollViewInsets = NO;
    NSURL *url = [NSURL URLWithString:self.urlTargetString];
    NSURLRequest *urlRequest = [NSURLRequest requestWithURL:url];
    [self.webView loadRequest:urlRequest];
    self.webView.scalesPageToFit = YES;
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressGesture.minimumPressDuration = 3.0;
    self.longPressGestureView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80, 15, 80, 51)];
    [self.navigationController.view addSubview:self.longPressGestureView];
    [self.longPressGestureView addGestureRecognizer:self.longPressGesture];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.longPressGesture = nil;
    [self.longPressGestureView removeFromSuperview];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [self showDebugMenu];
    }
}

- (void)showDebugMenu
{
    DLog(@"showing Debug menu");
}

@end

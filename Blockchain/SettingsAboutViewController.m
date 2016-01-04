//
//  SettingsAboutViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/15/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsAboutViewController.h"
#import "SettingsNavigationController.h"
#import "DebugTableViewController.h"

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
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    SettingsNavigationController *navigationController = (SettingsNavigationController *)self.navigationController;
    NSString *headerString;
    if ([self.urlTargetString containsString:TERMS_OF_SERVICE_URL_SUFFIX]) {
        headerString = BC_STRING_TERMS_OF_SERVICE;
    } else if ([self.urlTargetString containsString:PRIVACY_POLICY_URL_SUFFIX]) {
        headerString = BC_STRING_SETTINGS_PRIVACY_POLICY;
    }
    
    navigationController.headerLabel.text = headerString;
}

#pragma mark Debug Menu

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    self.longPressGesture.minimumPressDuration = DURATION_LONG_PRESS_GESTURE_DEBUG;
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
        DebugTableViewController *debugViewController = [[DebugTableViewController alloc] init];
        debugViewController.presenter = DEBUG_PRESENTER_SETTINGS_ABOUT;
        UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:debugViewController];
        [self presentViewController:navigationController animated:YES completion:nil];
    }
}

@end

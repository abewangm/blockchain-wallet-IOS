//
//  SettingsAboutViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/15/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsAboutViewController.h"
#import "SettingsNavigationController.h"

@interface SettingsAboutViewController ()
@property (weak, nonatomic) IBOutlet UIWebView *webView;
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

@end

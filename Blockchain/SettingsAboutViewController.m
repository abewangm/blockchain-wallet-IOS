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

@end

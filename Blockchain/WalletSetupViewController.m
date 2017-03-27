//
//  WalletSetupViewController.m
//  Blockchain
//
//  Created by kevinwu on 3/27/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "WalletSetupViewController.h"

@interface WalletSetupViewController ()

@end

@implementation WalletSetupViewController

- (id)initWithSetupDelegate:(UIViewController<SetupDelegate>*)delegate
{
    if (self = [super init]) {
        self.delegate = delegate;
    }
    return self;
}

- (void)loadView
{
    self.view = [[UIView alloc] initWithFrame:[self.delegate getFrame]];
    self.view.backgroundColor = [UIColor whiteColor];
    
    if (self.view == nil) {
        [super loadView];
    }
    
    UIView *bannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT + 80)];
    bannerView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:bannerView];
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    
    NSInteger numberOfPages = 2;
    
    UIView *touchIDView = [[UIView alloc] initWithFrame:self.view.frame];
    touchIDView.backgroundColor = [UIColor clearColor];
    UIButton *doneButtonTouchID = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 60, self.view.frame.size.width - 40, 30)];
    doneButtonTouchID.center = CGPointMake(self.view.frame.size.width/2, doneButtonTouchID.center.y);
    [doneButtonTouchID setTitleColor:COLOR_LIGHT_GRAY forState:UIControlStateNormal];
    [doneButtonTouchID setTitle:BC_STRING_ILL_DO_THIS_LATER forState:UIControlStateNormal];
    [touchIDView addSubview:doneButtonTouchID];
    
    UIView *emailView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height)];
    emailView.backgroundColor = [UIColor clearColor];
    UIButton *doneButtonEmail = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 60, self.view.frame.size.width - 40, 30)];
    doneButtonEmail.center = CGPointMake(self.view.frame.size.width/2, doneButtonEmail.center.y);
    [doneButtonEmail setTitleColor:COLOR_LIGHT_GRAY forState:UIControlStateNormal];
    [doneButtonEmail setTitle:BC_STRING_ILL_DO_THIS_LATER forState:UIControlStateNormal];
    [emailView addSubview:doneButtonEmail];
    
    [scrollView addSubview:touchIDView];
    [scrollView addSubview:emailView];
    
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width * numberOfPages, self.view.frame.size.height);
    [self.view addSubview:scrollView];
}

@end

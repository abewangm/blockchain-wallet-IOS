//
//  WalletSetupViewController.m
//  Blockchain
//
//  Created by kevinwu on 3/27/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "WalletSetupViewController.h"

@interface WalletSetupViewController ()
@property (nonatomic) UIScrollView *scrollView;
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
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:self.view.frame];
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    
    NSInteger numberOfPages = 2;
    
    [scrollView addSubview:[self setupTouchIDView]];
    [scrollView addSubview:[self setupEmailView]];
    
    scrollView.contentSize = CGSizeMake(self.view.frame.size.width * numberOfPages, self.view.frame.size.height);
    [self.view addSubview:scrollView];
    
    self.scrollView = scrollView;
}

- (UIView *)setupTouchIDView
{
    UIView *touchIDView = [[UIView alloc] initWithFrame:self.view.frame];
    
    UIView *bannerView = [self setupBannerViewWithImageName:@"bitcoin"];
    [touchIDView addSubview:bannerView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, bannerView.frame.size.height + 16, touchIDView.frame.size.width - 50, 50)];
    titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:20];
    titleLabel.textColor = COLOR_TEXT_DARK_GRAY;
    titleLabel.text = BC_STRING_TOUCH_ID;
    titleLabel.center = CGPointMake(touchIDView.center.x, titleLabel.center.y);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [touchIDView addSubview:titleLabel];
    
    UIButton *enableTouchIDButton = [self setupActionButton];
    [enableTouchIDButton setTitle:BC_STRING_ENABLE_TOUCH_ID forState:UIControlStateNormal];
    [enableTouchIDButton addTarget:self action:@selector(enableTouchID) forControlEvents:UIControlEventTouchUpInside];
    [touchIDView addSubview:enableTouchIDButton];
    
    UIButton *doneButton = [self setupDoneButton];
    [doneButton addTarget:self action:@selector(goToSecondPage) forControlEvents:UIControlEventTouchUpInside];
    [touchIDView addSubview:doneButton];
    
    return touchIDView;
}

- (UIView *)setupEmailView
{
    UIView *emailView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.size.width, 0, self.view.frame.size.width, self.view.frame.size.height)];
    
    UIView *bannerView = [self setupBannerViewWithImageName:@"bitcoin"];
    [emailView addSubview:bannerView];
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, bannerView.frame.size.height + 16, emailView.frame.size.width - 50, 50)];
    titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:20];
    titleLabel.textColor = COLOR_TEXT_DARK_GRAY;
    titleLabel.text = BC_STRING_REMINDER_CHECK_EMAIL_TITLE;
    titleLabel.center = CGPointMake(emailView.center.x - self.view.frame.size.width, titleLabel.center.y);
    titleLabel.textAlignment = NSTextAlignmentCenter;
    [emailView addSubview:titleLabel];
    
    UIButton *openMailButton = [self setupActionButton];
    [openMailButton setTitle:BC_STRING_OPEN_MAIL_APP forState:UIControlStateNormal];
    [openMailButton addTarget:self action:@selector(openMail) forControlEvents:UIControlEventTouchUpInside];
    [emailView addSubview:openMailButton];
    
    UIButton *doneButton = [self setupDoneButton];
    [doneButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [emailView addSubview:doneButton];
    
    return emailView;
}

- (UIButton *)setupActionButton
{
    UIButton *actionButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 60 - 30 - 16, self.view.frame.size.width - 40, 40)];
    actionButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:14];
    actionButton.center = CGPointMake(self.view.frame.size.width/2, actionButton.center.y);
    actionButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    [actionButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    return actionButton;
}

- (UIButton *)setupDoneButton
{
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 60, self.view.frame.size.width - 40, 40)];
    doneButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:14];
    doneButton.center = CGPointMake(self.view.frame.size.width/2, doneButton.center.y);
    [doneButton setTitleColor:COLOR_LIGHT_GRAY forState:UIControlStateNormal];
    [doneButton setTitle:BC_STRING_ILL_DO_THIS_LATER forState:UIControlStateNormal];
    return doneButton;
}

- (UIView *)setupBannerViewWithImageName:(NSString *)imageName
{
    UIView *bannerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT + 80)];
    bannerView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;

    UIImageView *imageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:imageName]];
    imageView.frame = CGRectMake(0, 0, 50, 50);
    imageView.center = bannerView.center;
    
    [bannerView addSubview:imageView];
    return bannerView;
}

- (void)goToSecondPage
{
    [self.scrollView setContentOffset:CGPointMake(self.view.frame.size.width, 0) animated:YES];
}

- (void)dismiss
{
    self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)openMail
{
    
}

- (void)enableTouchID
{
    
}

@end

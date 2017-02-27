//
//  BCNavigationController.m
//  Blockchain
//
//  Created by Kevin Wu on 10/12/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCNavigationController.h"

@interface BCNavigationController ()

@end

@implementation BCNavigationController

- (id)initWithRootViewController:(UIViewController *)rootViewController title:(NSString *)headerTitle;
{
    if (self = [super initWithRootViewController:rootViewController]) {
        self.headerTitle = headerTitle;
        self.shouldHideBusyView = YES; // default behavior
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    app.topViewControllerDelegate = self;
    
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT)];
    topBar.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBar];
    
    self.headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 17.5, self.view.frame.size.width - 160, 40)];
    self.headerLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_TOP_BAR_TEXT];
    self.headerLabel.textColor = [UIColor whiteColor];
    self.headerLabel.textAlignment = NSTextAlignmentCenter;
    self.headerLabel.adjustsFontSizeToFitWidth = YES;
    self.headerLabel.text = self.headerTitle;
    [topBar addSubview:self.headerLabel];
    
    self.closeButton = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeButton.frame = CGRectMake(self.view.frame.size.width - 80, 15, 80, 51);
    self.closeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 20);
    self.closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    self.closeButton.center = CGPointMake(self.closeButton.center.x, self.headerLabel.center.y);
    [self.closeButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:self.closeButton];
    
    self.backButton = [[UIButton alloc] initWithFrame:CGRectZero];
    self.backButton.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
    self.backButton.frame = CGRectMake(0, 12, 85, 51);
    self.backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [self.backButton setTitle:@"" forState:UIControlStateNormal];
    [self.backButton setImage:[UIImage imageNamed:@"back_chevron_icon"] forState:UIControlStateNormal];
    [self.backButton addTarget:self action:@selector(popViewController) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:self.backButton];
    
    [self setupBusyView];
}

- (void)setupBusyView
{
    BCFadeView *busyView = [[BCFadeView alloc] initWithFrame:self.view.frame];
    busyView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    UIView *textWithSpinnerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 110)];
    textWithSpinnerView.backgroundColor = [UIColor whiteColor];
    [busyView addSubview:textWithSpinnerView];
    textWithSpinnerView.center = busyView.center;
    
    UILabel *busyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, BUSY_VIEW_LABEL_WIDTH, BUSY_VIEW_LABEL_HEIGHT)];
    busyLabel.adjustsFontSizeToFitWidth = YES;
    busyLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:BUSY_VIEW_LABEL_FONT_SYSTEM_SIZE];
    busyLabel.alpha = BUSY_VIEW_LABEL_ALPHA;
    busyLabel.textAlignment = NSTextAlignmentCenter;
    busyLabel.text = BC_STRING_LOADING_SYNCING_WALLET;
    busyLabel.center = CGPointMake(textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 + 15);
    [textWithSpinnerView addSubview:busyLabel];
    self.busyLabel = busyLabel;
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 - 15);
    [textWithSpinnerView addSubview:spinner];
    [textWithSpinnerView bringSubviewToFront:spinner];
    [spinner startAnimating];
    
    busyView.containerView = textWithSpinnerView;
    [busyView fadeOut];
    
    [self.view addSubview:busyView];
    
    [self.view bringSubviewToFront:busyView];
    
    self.busyView = busyView;
}

- (void)setHeaderTitle:(NSString *)headerTitle
{
    _headerTitle = headerTitle;
    self.headerLabel.text = headerTitle;
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    if (self.viewControllers.count > 1) {
        self.
        self.backButton.hidden = NO;
        self.closeButton.hidden = YES;
    } else {
        self.backButton.hidden = YES;
        self.closeButton.hidden = NO;
    }
}

- (void)popViewController
{
    if (self.viewControllers.count > 1) {
        [self popViewControllerAnimated:YES];
    } else {
        [self dismiss];
    }
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
    app.topViewControllerDelegate = nil;
}

#pragma mark Busy View Delegate

- (void)showBusyViewWithLoadingText:(NSString *)text
{
    self.busyLabel.text = text;
    [self.view bringSubviewToFront:self.busyView];
    if (self.busyView.alpha < 1.0) {
        [self.busyView fadeIn];
    }
}

- (void)updateBusyViewLoadingText:(NSString *)text
{
    if (self.busyView.alpha == 1.0) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self.busyLabel setText:text];
        }];
    }
}

- (void)hideBusyView
{
    if (self.busyView.alpha == 1.0 && self.shouldHideBusyView) {
        [self.busyView fadeOut];
    }
}

- (void)presentAlertController:(UIAlertController *)alertController
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION_LONG * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.presentedViewController) {
            [self.presentedViewController presentViewController:alertController animated:YES completion:nil];
        } else {
            [self presentViewController:alertController animated:YES completion:nil];
        }
    });
}

@end

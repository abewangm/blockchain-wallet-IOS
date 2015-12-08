//
//  UpgradeDetailsViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/7/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//
#import "AppDelegate.h"
#import "UpgradeDetailsViewController.h"

@interface UpgradeDetailsViewController ()
@property (strong, nonatomic) IBOutlet UITextView *featuresTextView;
@property (strong, nonatomic) IBOutlet UIButton *upgradeWalletButton;
@end

@implementation UpgradeDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = COLOR_BLOCKCHAIN_UPGRADE_BLUE;
    self.featuresTextView.text = BC_STRING_UPGRADE_FEATURES;
    self.featuresTextView.textColor = COLOR_UPGRADE_TEXT_BLUE;
    self.featuresTextView.textContainerInset = UIEdgeInsetsZero;
    self.featuresTextView.textContainer.lineFragmentPadding = 0;
    
    self.upgradeWalletButton.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    self.upgradeWalletButton.clipsToBounds = YES;
    self.upgradeWalletButton.layer.cornerRadius = 20;
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];
}

- (IBAction)cancelUpgradeButtonTapped:(UIButton *)sender
{
    [self dismissSelf];
}

- (IBAction)upgradeWalletButtonTapped:(UIButton *)sender
{
    [app.wallet loading_start_upgrade_to_hd];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [app closeSideMenu];
        [app.wallet performSelector:@selector(upgradeToHDWallet) withObject:nil afterDelay:0.1f];
    });
    [self dismissSelf];
}

- (void)dismissSelf
{
    UIViewController *viewController = self.presentingViewController;
    while (viewController.presentingViewController) {
        viewController = viewController.presentingViewController;
    }
    [viewController dismissViewControllerAnimated:YES completion:NULL];
}

@end

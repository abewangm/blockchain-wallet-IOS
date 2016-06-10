//
//  UpgradeDetailsViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/7/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//
#import "AppDelegate.h"
#import "UpgradeDetailsViewController.h"
#import "UILabel+MultiLineAutoSize.h"

@interface UpgradeDetailsViewController ()
@property (strong, nonatomic) IBOutlet UITextView *featuresTextView;
@property (strong, nonatomic) IBOutlet UILabel *upgradeTitleLabel;
@property (strong, nonatomic) IBOutlet UIButton *upgradeWalletButton;
@end

@implementation UpgradeDetailsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = COLOR_BLOCKCHAIN_UPGRADE_BLUE;
    self.upgradeTitleLabel.text = BC_STRING_UPGRADE_TITLE;
    [self.upgradeTitleLabel adjustFontSizeToFit];
    self.featuresTextView.text = [NSString stringWithFormat:@"%@\n\n\u2022 %@\n\u2022 %@\n\u2022 %@\n\u2022 %@\n\u2022 %@\n\n%@", BC_STRING_UPGRADE_FEATURES_WHATS_BETTER, BC_STRING_UPGRADE_FEATURES_REDESIGNED_USER_EXPERIENCE, BC_STRING_UPGRADE_FEATURES_ROBUST_SECURITY_CENTER, BC_STRING_UPGRADE_FEATURES_ENHANCED_PRIVACY, BC_STRING_UPGRADE_FEATURES_SIMPLIFIED_BACKUP, BC_STRING_UPGRADE_FEATURES_CUSTOMIZED_FUND_MANAGEMENT, BC_STRING_UPGRADE_FEATURES_SHARED_COIN_NOT_SUPPORTED];
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
    if (![app checkInternetConnection]) {
        return;
    }
    
    [app.wallet loading_start_upgrade_to_hd];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [app closeSideMenu];
        [app.wallet performSelector:@selector(upgradeToV3Wallet) withObject:nil afterDelay:0.1f];
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

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
@property (strong, nonatomic) IBOutlet UIButton *cancelButton;
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
    self.featuresTextView.text = [NSString stringWithFormat:@"%@\n\n\u2022 %@\n\u2022 %@\n\u2022 %@\n\u2022 %@\n\u2022 %@", BC_STRING_UPGRADE_FEATURES_WHATS_BETTER, BC_STRING_UPGRADE_FEATURES_REDESIGNED_USER_EXPERIENCE, BC_STRING_UPGRADE_FEATURES_ROBUST_SECURITY_CENTER, BC_STRING_UPGRADE_FEATURES_ENHANCED_PRIVACY, BC_STRING_UPGRADE_FEATURES_SIMPLIFIED_BACKUP, BC_STRING_UPGRADE_FEATURES_CUSTOMIZED_FUND_MANAGEMENT];
    self.featuresTextView.textColor = COLOR_UPGRADE_TEXT_BLUE;
    self.featuresTextView.textContainerInset = UIEdgeInsetsZero;
    self.featuresTextView.textContainer.lineFragmentPadding = 0;
    
    self.upgradeWalletButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.cancelButton setTitle:BC_STRING_LOGOUT_AND_FORGET_WALLET forState:UIControlStateNormal];
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
    UIAlertController *forgetWalletAlert = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING message:BC_STRING_FORGET_WALLET_DETAILS preferredStyle:UIAlertControllerStyleAlert];
    [forgetWalletAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [forgetWalletAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_FORGET_WALLET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        DLog(@"forgetting wallet");
        [[[self presentingViewController] presentingViewController] dismissViewControllerAnimated:YES completion:^{
            [app logout];
            [app forgetWallet];
            [app showWelcome];
        }];
    }]];
    [self presentViewController:forgetWalletAlert animated:YES completion:nil];
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

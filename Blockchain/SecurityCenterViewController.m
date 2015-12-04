//
//  SecurityCenterViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/2/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//

#import "SecurityCenterViewController.h"
#import "SettingsTableViewController.h"
#import "SettingsTwoStepViewController.h"
#import "AppDelegate.h"

@interface SecurityCenterViewController ()
@property (strong, nonatomic) IBOutlet UIButton *verifyEmailButton;
@property (strong, nonatomic) IBOutlet UILabel *verifyEmailLabel;
@property (strong, nonatomic) IBOutlet UIImageView *verifyEmailCheckImageView;

@property (strong, nonatomic) IBOutlet UIButton *backupPhraseButton;
@property (strong, nonatomic) IBOutlet UILabel *backupPhraseLabel;
@property (strong, nonatomic) IBOutlet UIImageView *backupPhraseCheckImageView;

@property (strong, nonatomic) IBOutlet UIButton *linkMobileButton;
@property (strong, nonatomic) IBOutlet UILabel *linkMobileLabel;
@property (strong, nonatomic) IBOutlet UIImageView *linkMobileCheckImageView;

@property (strong, nonatomic) IBOutlet UIButton *storeHintButton;
@property (strong, nonatomic) IBOutlet UILabel *storeHintLabel;
@property (strong, nonatomic) IBOutlet UIImageView *storeHintCheckImageView;

@property (strong, nonatomic) IBOutlet UIButton *enableTwoStepButton;
@property (strong, nonatomic) IBOutlet UILabel *enableTwoStepLabel;
@property (strong, nonatomic) IBOutlet UIImageView *enableTwoStepCheckImageView;

@property (strong, nonatomic) IBOutlet UIProgressView *progressView;

@property (nonatomic) SettingsTableViewController *settingsController;
@property (nonatomic) BackupNavigationViewController *backupController;
@end

@implementation SecurityCenterViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    SettingsNavigationController *navigationController = (SettingsNavigationController *)self.navigationController;
    navigationController.headerLabel.text = BC_STRING_SECURITY_CENTER;
    
    if (!self.settingsController) {
        self.settingsController = [[SettingsTableViewController alloc] init];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.settingsController.alertTargetViewController = self;
    [self.settingsController reload];
}

- (void)updateUI
{
    int completedItems = 0;
    
    BOOL hasVerifiedEmail = [self.settingsController hasVerifiedEmail];
    self.verifyEmailLabel.text = hasVerifiedEmail ? BC_STRING_EMAIL_VERIFIED : BC_STRING_VERIFY_EMAIL;
    self.verifyEmailLabel.textColor = hasVerifiedEmail ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    self.verifyEmailButton.enabled = hasVerifiedEmail ? NO : YES;
    if (hasVerifiedEmail) {
        completedItems++;
    }

    BOOL hasBackedUpPhrase = app.wallet.isRecoveryPhraseVerified;
    self.backupPhraseLabel.text = hasBackedUpPhrase ? BC_STRING_PHRASE_BACKED : BC_STRING_BACKUP_PHRASE;
    self.backupPhraseLabel.textColor = hasBackedUpPhrase ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    if (hasBackedUpPhrase) {
        completedItems++;
    }

    BOOL hasLinkedMobileNumber = [self.settingsController hasVerifiedMobileNumber];
    self.linkMobileLabel.text = hasLinkedMobileNumber ? BC_STRING_MOBILE_LINKED : BC_STRING_LINK_MOBILE;
    self.linkMobileLabel.textColor = hasLinkedMobileNumber ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    self.linkMobileButton.enabled = hasLinkedMobileNumber ? NO : YES;
    if (hasLinkedMobileNumber) {
        completedItems++;
    }

    BOOL hasStoredPasswordHint = [self.settingsController hasStoredPasswordHint];
    self.storeHintLabel.text = hasStoredPasswordHint ? BC_STRING_HINT_STORED : BC_STRING_STORE_HINT;
    self.storeHintLabel.textColor = hasStoredPasswordHint ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    self.storeHintButton.enabled = hasStoredPasswordHint ? NO : YES;
    if (hasStoredPasswordHint) {
        completedItems++;
    }

    BOOL hasEnabledTwoStep = [self.settingsController hasEnabledTwoStep];
    self.enableTwoStepLabel.text = hasEnabledTwoStep ? BC_STRING_TWO_STEP_ENABLED : BC_STRING_ENABLE_TWO_STEP;
    self.enableTwoStepLabel.textColor = hasEnabledTwoStep ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    self.enableTwoStepButton.enabled = hasEnabledTwoStep ? NO : YES;
    if (hasEnabledTwoStep) {
        completedItems++;
    }
    
    self.progressView.progress = (float)completedItems/5;
}

- (IBAction)verifyEmailButtonTapped:(UIButton *)sender
{
    [self.settingsController verifyEmailTapped];
}

- (IBAction)backupButtonTapped:(UIButton *)sender
{
    if (!self.backupController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_BACKUP bundle: nil];
        self.backupController = [storyboard instantiateViewControllerWithIdentifier:NAVIGATION_CONTROLLER_NAME_BACKUP];
    }
    
    // Pass the wallet to the backup navigation controller, so we don't have to make the AppDelegate available in Swift.
    self.backupController.wallet = app.wallet;
    
    self.backupController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:self.backupController animated:YES completion:nil];
}

- (IBAction)linkMobileTapped:(UIButton *)sender
{
    [self.settingsController linkMobileTapped];
}

- (IBAction)storeHintTapped:(UIButton *)sender
{
    [self.settingsController storeHintTapped];
}

- (IBAction)enableTwoStepTapped:(UIButton *)sender
{
    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_TWO_STEP sender:nil];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_TWO_STEP]) {
        SettingsTwoStepViewController *twoStepViewController = (SettingsTwoStepViewController *)segue.destinationViewController;
        twoStepViewController.settingsController = self.settingsController;
        self.settingsController.alertTargetViewController = twoStepViewController;
    }
}

@end

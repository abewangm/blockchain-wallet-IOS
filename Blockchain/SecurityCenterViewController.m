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

@property (strong, nonatomic) IBOutlet UIButton *blockTorButton;
@property (strong, nonatomic) IBOutlet UILabel *blockTorLabel;
@property (strong, nonatomic) IBOutlet UIImageView *blockTorCheckImageView;

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
    
    if ([self updateEmail]) {
        completedItems++;
    }

    if ([self updatePhrase]) {
        completedItems++;
    }

    if ([self updateMobile]) {
        completedItems++;
    }

    if ([self updateHint]) {
        completedItems++;
    }

    if ([self updateTwoStep]) {
        completedItems++;
    }

    if ([self updateTor]) {
        completedItems++;
    }
    
    self.progressView.progress = (float)completedItems/6;
}

- (BOOL)updateEmail
{
    BOOL hasVerifiedEmail = [self.settingsController hasVerifiedEmail];
    self.verifyEmailLabel.text = hasVerifiedEmail ? BC_STRING_EMAIL_VERIFIED : BC_STRING_VERIFY_EMAIL;
    self.verifyEmailLabel.textColor = hasVerifiedEmail ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    [self.verifyEmailButton setImage: hasVerifiedEmail ? [UIImage imageNamed:@"emailb"] : [UIImage imageNamed:@"email"] forState:UIControlStateNormal];
    self.verifyEmailButton.enabled = hasVerifiedEmail ? NO : YES;
    return hasVerifiedEmail;
}

- (BOOL)updatePhrase
{
    BOOL hasBackedUpPhrase = app.wallet.isRecoveryPhraseVerified;
    self.backupPhraseLabel.text = hasBackedUpPhrase ? BC_STRING_PHRASE_BACKED : BC_STRING_BACKUP_PHRASE;
    self.backupPhraseLabel.textColor = hasBackedUpPhrase ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    [self.backupPhraseButton setImage: hasBackedUpPhrase ? [UIImage imageNamed:@"phraseb"] : [UIImage imageNamed:@"phrase"] forState:UIControlStateNormal];
    self.backupPhraseButton.enabled = hasBackedUpPhrase ? NO : YES;
    return hasBackedUpPhrase;
}

- (BOOL)updateMobile
{
    BOOL hasLinkedMobileNumber = [self.settingsController hasVerifiedMobileNumber];
    self.linkMobileLabel.text = hasLinkedMobileNumber ? BC_STRING_MOBILE_LINKED : BC_STRING_LINK_MOBILE;
    self.linkMobileLabel.textColor = hasLinkedMobileNumber ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    self.linkMobileButton.enabled = hasLinkedMobileNumber ? NO : YES;
    [self.linkMobileButton setImage: hasLinkedMobileNumber ? [UIImage imageNamed:@"phoneb"] : [UIImage imageNamed:@"phone"] forState:UIControlStateNormal];
    return hasLinkedMobileNumber;
}

- (BOOL)updateHint
{
    BOOL hasStoredPasswordHint = [self.settingsController hasStoredPasswordHint];
    self.storeHintLabel.text = hasStoredPasswordHint ? BC_STRING_HINT_STORED : BC_STRING_STORE_HINT;
    self.storeHintLabel.textColor = hasStoredPasswordHint ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    self.storeHintButton.enabled = hasStoredPasswordHint ? NO : YES;
    [self.storeHintButton setImage: hasStoredPasswordHint ? [UIImage imageNamed:@"keyb"] : [UIImage imageNamed:@"key"] forState:UIControlStateNormal];
    return hasStoredPasswordHint;
}

- (BOOL)updateTwoStep
{
    BOOL hasEnabledTwoStep = [self.settingsController hasEnabledTwoStep];
    self.enableTwoStepLabel.text = hasEnabledTwoStep ? BC_STRING_TWO_STEP_ENABLED : BC_STRING_ENABLE_TWO_STEP;
    self.enableTwoStepLabel.textColor = hasEnabledTwoStep ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    self.enableTwoStepButton.enabled = hasEnabledTwoStep ? NO : YES;
    [self.enableTwoStepButton setImage: hasEnabledTwoStep ? [UIImage imageNamed:@"2fab"] : [UIImage imageNamed:@"2fa"] forState:UIControlStateNormal];
    return hasEnabledTwoStep;
}

- (BOOL)updateTor
{
    BOOL hasBlockedTorRequests = [self.settingsController hasBlockedTorRequests];
    self.blockTorLabel.text = hasBlockedTorRequests ? BC_STRING_TOR_BLOCKED : BC_STRING_BLOCK_TOR;
    self.blockTorLabel.textColor = hasBlockedTorRequests ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    self.blockTorButton.enabled = hasBlockedTorRequests ? NO : YES;
    [self.blockTorButton setImage: hasBlockedTorRequests ? [UIImage imageNamed:@"torb"] : [UIImage imageNamed:@"tor"] forState:UIControlStateNormal];
    return hasBlockedTorRequests;
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

- (IBAction)blockTorTapped:(UIButton *)sender
{
    [self.settingsController blockTorTapped];
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

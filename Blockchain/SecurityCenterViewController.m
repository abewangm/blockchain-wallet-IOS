//
//  SecurityCenterViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/2/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SecurityCenterViewController.h"
#import "SettingsTableViewController.h"
#import "SettingsTwoStepViewController.h"
#import "RootService.h"
#import "Blockchain-Swift.h"

@interface SecurityCenterViewController ()
@property (strong, nonatomic) IBOutlet UIImageView *securityLevelImageView;
@property (strong, nonatomic) IBOutlet UILabel *instructionsLabel;

@property (strong, nonatomic) IBOutlet UIButton *verifyEmailButton;
@property (strong, nonatomic) IBOutlet UILabel *verifyEmailLabel;
@property (strong, nonatomic) IBOutlet UIImageView *verifyEmailCheckImageView;

@property (strong, nonatomic) IBOutlet UIButton *backupPhraseButton;
@property (strong, nonatomic) IBOutlet UILabel *backupPhraseLabel;
@property (strong, nonatomic) IBOutlet UIImageView *backupPhraseCheckImageView;

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
    
    [self setupCheckImageViews];
    
    if (!self.settingsController) {
        self.settingsController = [[SettingsTableViewController alloc] init];
    }
    
    [self updateUI];
}

- (void)setupCheckImageViews
{
    self.verifyEmailCheckImageView.image = [self.verifyEmailCheckImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.verifyEmailCheckImageView setTintColor:COLOR_SECURITY_CENTER_GREEN];
    
    self.backupPhraseCheckImageView.image = [self.backupPhraseCheckImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.backupPhraseCheckImageView setTintColor:COLOR_SECURITY_CENTER_GREEN];
    
    self.enableTwoStepCheckImageView.image = [self.enableTwoStepCheckImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.enableTwoStepCheckImageView setTintColor:COLOR_SECURITY_CENTER_GREEN];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.settingsController.alertTargetViewController = self;
    [self updateUI];
}

- (void)updateUI
{
    [self updateEmail];
    [self updatePhrase];
    [self updateTwoStep];
    
    int score = [app.wallet securityCenterScore];
    
    int completedItemsCount = [app.wallet securityCenterCompletedItemsCount];
    self.progressView.progress = (float)completedItemsCount/3;
    if (score == 1) {
        self.securityLevelImageView.image = [UIImage imageNamed:@"security2"];
        self.progressView.progressTintColor = COLOR_SECURITY_CENTER_YELLOW;
        self.instructionsLabel.text = BC_STRING_SECURITY_CENTER_INSTRUCTIONS;
    } else if (score > 1) {
        self.securityLevelImageView.image = [UIImage imageNamed:@"security3"];
        self.progressView.progressTintColor = COLOR_SECURITY_CENTER_GREEN;
        self.instructionsLabel.text = completedItemsCount == 3 ? BC_STRING_SECURITY_CENTER_COMPLETED : BC_STRING_SECURITY_CENTER_INSTRUCTIONS;
    } else {
        self.securityLevelImageView.image = [UIImage imageNamed:@"security1"];
        self.progressView.progressTintColor = COLOR_SECURITY_CENTER_RED;
        self.instructionsLabel.text = BC_STRING_SECURITY_CENTER_INSTRUCTIONS;
    }
}

- (void)updateEmail
{
    BOOL hasVerifiedEmail = [app.wallet hasVerifiedEmail];
    self.verifyEmailLabel.text = hasVerifiedEmail ? BC_STRING_EMAIL_VERIFIED : BC_STRING_VERIFY_EMAIL;
    self.verifyEmailLabel.textColor = hasVerifiedEmail ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    [self.verifyEmailButton setImage: hasVerifiedEmail ? [UIImage imageNamed:@"emailb"] : [UIImage imageNamed:@"email"] forState:UIControlStateNormal];
    self.verifyEmailButton.enabled = hasVerifiedEmail ? NO : YES;
    self.verifyEmailCheckImageView.hidden = hasVerifiedEmail ? NO : YES;
}

- (void)updatePhrase
{
    BOOL hasBackedUpPhrase = app.wallet.isRecoveryPhraseVerified;
    self.backupPhraseLabel.text = hasBackedUpPhrase ? BC_STRING_PHRASE_BACKED : BC_STRING_BACKUP_PHRASE;
    self.backupPhraseLabel.textColor = hasBackedUpPhrase ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    [self.backupPhraseButton setImage: hasBackedUpPhrase ? [UIImage imageNamed:@"phraseb"] : [UIImage imageNamed:@"phrase"] forState:UIControlStateNormal];
    self.backupPhraseButton.enabled = hasBackedUpPhrase ? NO : YES;
    self.backupPhraseCheckImageView.hidden = hasBackedUpPhrase ? NO : YES;
}

- (void)updateTwoStep
{
    BOOL hasEnabledTwoStep = [app.wallet hasEnabledTwoStep];
    self.enableTwoStepLabel.text = hasEnabledTwoStep ? BC_STRING_TWO_STEP_ENABLED : BC_STRING_ENABLE_TWO_STEP;
    self.enableTwoStepLabel.textColor = hasEnabledTwoStep ? COLOR_SECURITY_CENTER_GREEN : COLOR_TEXT_FIELD_BORDER_GRAY;
    self.enableTwoStepButton.enabled = hasEnabledTwoStep ? NO : YES;
    [self.enableTwoStepButton setImage: hasEnabledTwoStep ? [UIImage imageNamed:@"2fab"] : [UIImage imageNamed:@"2fa"] forState:UIControlStateNormal];
    self.enableTwoStepCheckImageView.hidden = hasEnabledTwoStep ? NO : YES;
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
    
    self.backupController.wallet = app.wallet;
    
    self.backupController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:self.backupController animated:YES completion:nil];
}

- (IBAction)linkMobileTapped:(UIButton *)sender
{
    [self.settingsController linkMobileTapped];
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

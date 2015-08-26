//
//  SettingsTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/13/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "SettingsSelectorTableViewController.h"
#import "SettingsAboutViewController.h"
#import "SettingsBitcoinUnitTableViewController.h"
#import "AppDelegate.h"

#define TERMS_OF_SERVICE_URL @"https://blockchain.info/Resources/TermsofServicePolicy.pdf"
#define PRIVACY_POLICY_URL @"https://blockchain.info/Resources/PrivacyPolicy.pdf"


const int textFieldTagVerifyEmail = 5;
const int textFieldTagChangeEmail = 4;

const int accountDetailsSection = 0;
const int accountDetailsIdentifier = 0;
const int accountDetailsEmail = 1;

const int displaySection = 1;
const int displayLocalCurrency = 0;
const int displayBtcUnit = 1;

const int feesSection = 2;
const int feePerKb = 0;

const int aboutSection = 3;
const int aboutTermsOfService = 0;
const int aboutPrivacyPolicy = 1;

@interface SettingsTableViewController () <CurrencySelectorDelegate, BtcSelectorDelegate, UIAlertViewDelegate, UITextFieldDelegate>
@property (nonatomic, copy) NSDictionary *availableCurrenciesDictionary;
@property (nonatomic, copy) NSDictionary *accountInfoDictionary;
@property (nonatomic, copy) NSDictionary *allCurrencySymbolsDictionary;
@property (nonatomic) UIAlertView *verifyEmailAlertView;
@property (nonatomic) UIAlertView *changeEmailAlertView;
@property (nonatomic) UIAlertView *errorLoadingAlertView;
@property (nonatomic) UIAlertView *changeFeeAlertView;
@property (nonatomic, copy) NSString *enteredEmailString;
@property (nonatomic, copy) NSString *emailString;
@property (nonatomic) float currentFeePerKb;
@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self getAccountInfo];
    
    [self getAllCurrencySymbols];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (self.didChangeFee) {
        [app showBusyViewWithLoadingText:BC_STRING_LOADING_UPDATING_SETTINGS];
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_FINISHED_CHANGING_FEE object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    self.didChangeFee = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedChangingFee) name:NOTIFICATION_KEY_FINISHED_CHANGING_FEE object:nil];
}

- (void)finishedChangingFee
{
    self.didChangeFee = NO;
}

- (void)getAllCurrencySymbols
{
    __block id notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_GET_ALL_CURRENCY_SYMBOLS_SUCCESS object:nil queue:nil usingBlock:^(NSNotification *note) {
        DLog(@"SettingsTableViewController: gotCurrencySymbols");
        self.allCurrencySymbolsDictionary = note.userInfo;
        [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver name:NOTIFICATION_KEY_GET_ALL_CURRENCY_SYMBOLS_SUCCESS object:nil];
    }];
    
    [app.wallet getAllCurrencySymbols];
}

- (void)setAllCurrencySymbolsDictionary:(NSDictionary *)allCurrencySymbolsDictionary
{
    _allCurrencySymbolsDictionary = allCurrencySymbolsDictionary;
    
    [self reloadTableView];
}

- (void)getAccountInfo;
{
    __block id notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil queue:nil usingBlock:^(NSNotification *note) {
        DLog(@"SettingsTableViewController: gotAccountInfo");
        self.accountInfoDictionary = note.userInfo;
        [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
    }];
    
    [app.wallet getAccountInfo];
}

- (void)setAccountInfoDictionary:(NSDictionary *)accountInfoDictionary
{
    _accountInfoDictionary = accountInfoDictionary;
    
    if (_accountInfoDictionary[@"currencies"] != nil) {
        self.availableCurrenciesDictionary = _accountInfoDictionary[@"currencies"];
    }
    
    NSString *emailString = _accountInfoDictionary[@"email"];
    
    if (emailString != nil) {
        self.emailString = emailString;
    }
    
    [self reloadTableView];
}

- (void)changeLocalCurrencySuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_LOCAL_CURRENCY_SUCCESS object:nil];
    
    [self getHistory];
}

- (void)getHistory
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadTableView) name:NOTIFICATION_KEY_GET_HISTORY_SUCCESS object:nil];
    [app.wallet getHistory];
}

- (void)reloadTableView
{
    [self.tableView reloadData];
}

+ (UIFont *)fontForCell
{
    return [UIFont fontWithName:@"Helvetica Neue" size:15];
}

+ (UIFont *)fontForCellSubtitle
{
    return [UIFont fontWithName:@"Helvetica Neue" size:12];
}

- (CurrencySymbol *)getLocalSymbolFromLatestResponse
{
    return app.latestResponse.symbol_local;
}

- (CurrencySymbol *)getBtcSymbolFromLatestResponse
{
    return app.latestResponse.symbol_btc;
}

- (BOOL)hasAddedEmail
{
    return [self.accountInfoDictionary objectForKey:@"email"] ? YES : NO;
}

- (BOOL)hasVerifiedEmail
{
    return [[self.accountInfoDictionary objectForKey:@"email_verified"] boolValue];
}

- (NSString *)getUserEmail
{
    return [self.accountInfoDictionary objectForKey:@"email"];
}

- (float)getFeePerKb
{
    uint64_t unconvertedFee = [app.wallet getTransactionFee];
    float convertedFee = unconvertedFee / [[NSNumber numberWithInt:SATOSHI] floatValue];
    self.currentFeePerKb = convertedFee;
    return convertedFee;
}

- (void)alertViewToChangeFee
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_SETTINGS_CHANGE_FEE_TITLE message:[[NSString alloc] initWithFormat:BC_STRING_SETTINGS_CHANGE_FEE_MESSAGE_ARGUMENT, self.currentFeePerKb] delegate:self cancelButtonTitle:BC_STRING_CANCEL otherButtonTitles:BC_STRING_DONE, nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.spellCheckingType = UITextSpellCheckingTypeNo;
    textField.text = [[NSString alloc] initWithFormat:@"%.4f", self.currentFeePerKb];
    textField.keyboardType = UIKeyboardTypeDecimalPad;
    [alertView show];
    self.changeFeeAlertView = alertView;
}

- (void)alertViewForErrorLoadingSettings
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_SETTINGS_ERROR_LOADING_TITLE message:BC_STRING_SETTINGS_ERROR_LOADING_MESSAGE delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
    [alertView show];
    self.errorLoadingAlertView = alertView;
}

- (void)alertViewToChangeEmail:(BOOL)hasAddedEmail
{
    NSString *alertViewTitle = hasAddedEmail ? BC_STRING_SETTINGS_CHANGE_EMAIL :BC_STRING_ADD_EMAIL;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertViewTitle message:BC_STRING_PLEASE_PROVIDE_AN_EMAIL_ADDRESS delegate:self cancelButtonTitle:BC_STRING_CANCEL otherButtonTitles:BC_STRING_SETTINGS_VERIFY, nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.spellCheckingType = UITextSpellCheckingTypeNo;
    textField.tag = textFieldTagChangeEmail;
    textField.delegate = self;
    textField.returnKeyType = UIReturnKeyDone;
    [alertView show];
    self.changeEmailAlertView = alertView;
}

- (void)alertViewToVerifyEmail
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_SETTINGS_VERIFY_EMAIL_ENTER_CODE message:[[NSString alloc] initWithFormat:BC_STRING_SETTINGS_SENT_TO_ARGUMENT, self.emailString] delegate:self cancelButtonTitle:BC_STRING_CANCEL otherButtonTitles: BC_STRING_SETTINGS_VERIFY_EMAIL_RESEND, BC_STRING_SETTINGS_CHANGE_EMAIL, nil];
    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.spellCheckingType = UITextSpellCheckingTypeNo;
    textField.tag = textFieldTagVerifyEmail;
    textField.delegate = self;
    textField.returnKeyType = UIReturnKeyDone;
    textField.placeholder = BC_STRING_ENTER_VERIFICATION_CODE;
    [alertView show];
    self.verifyEmailAlertView = alertView;
}

- (void)alertViewForVerifyingEmailSuccess
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_SUCCESS message:BC_STRING_SETTINGS_EMAIL_VERIFIED delegate:self cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
    [alertView show];
}

- (void)resendVerificationEmail
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resendVerificationEmailSuccess) name:NOTIFICATION_KEY_RESEND_VERIFICATION_EMAIL_SUCCESS object:nil];
    
    [app.wallet resendVerificationEmail:self.emailString];
}

- (void)resendVerificationEmailSuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_RESEND_VERIFICATION_EMAIL_SUCCESS object:nil];
    
    [self alertViewToVerifyEmail];
}

- (void)changeEmail:(NSString *)emailString
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeEmailSuccess) name:NOTIFICATION_KEY_CHANGE_EMAIL_SUCCESS object:nil];
    
    self.enteredEmailString = emailString;
    
    [app.wallet changeEmail:emailString];
}

- (void)changeEmailSuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_EMAIL_SUCCESS object:nil];
    
    self.emailString = self.enteredEmailString;
    
    [self alertViewToVerifyEmail];
}

- (void)verifyEmailWithCode:(NSString *)codeString
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verifyEmailWithCodeSuccess) name:NOTIFICATION_KEY_VERIFY_EMAIL_SUCCESS object:nil];
    
    [app.wallet verifyEmailWithCode:codeString];
}

- (void)verifyEmailWithCodeSuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_VERIFY_EMAIL_SUCCESS object:nil];
    
    [self getAccountInfo];
    
    [self alertViewForVerifyingEmailSuccess];
}

#pragma mark AlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    // Not the smoothest dismissal of the keyboard but better than no animation
    BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
    [textField resignFirstResponder];
    
    if ([alertView isEqual:self.changeEmailAlertView]) {
        switch (buttonIndex) {
            case 0: {
                // If the user cancels right after adding a legitimate email address, update the tableView so that it says "Please verify" instead of "Please add"
                UITableViewCell *emailCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:accountDetailsEmail inSection:accountDetailsSection]];
                if ([emailCell.detailTextLabel.text isEqualToString:BC_STRING_SETTINGS_PLEASE_ADD_EMAIL] && [alertView.title isEqualToString:BC_STRING_SETTINGS_CHANGE_EMAIL]) {
                    [self getAccountInfo];
                }
                return;
            }
            case 1: {
                [self changeEmail:[alertView textFieldAtIndex:0].text];
                return;
            }
        }
        return;
    } else if ([alertView isEqual:self.verifyEmailAlertView]) {
        switch (buttonIndex) {
            case 0: {
                // If the user cancels right after adding a legitimate email address, update the tableView so that it says "Please verify" instead of "Please add"
                if ([[self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:accountDetailsEmail inSection:accountDetailsSection]].detailTextLabel.text isEqualToString:BC_STRING_SETTINGS_PLEASE_ADD_EMAIL] || ![[self getUserEmail] isEqualToString:self.emailString]) {
                    [self getAccountInfo];
                }
                return;
            }
            case 1: {
                [self resendVerificationEmail];
                return;
            }
            case 2: {
                // Give time for the alertView to fully dismiss, otherwise its keyboard will pop up if entered email is invalid
                dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
                dispatch_after(delayTime, dispatch_get_main_queue(), ^{
                    [self alertViewToChangeEmail:YES];
                });
                return;
            }
        }
        return;
    } else if ([alertView isEqual:self.changeFeeAlertView]) {
        switch (buttonIndex) {
            case 0: {
                return;
            }
            case 1: {
                BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
                float fee = [textField.text floatValue];
                if (fee > 0.01) {
                    [app standardNotify:BC_STRING_SETTINGS_FEE_TOO_HIGH];
                    return;
                }
                
                NSNumber *unconvertedFee = [NSNumber numberWithFloat:fee * [[NSNumber numberWithInt:SATOSHI] floatValue]];
                uint64_t convertedFee = (uint64_t)[unconvertedFee longLongValue];
                [app.wallet setTransactionFee:convertedFee];
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:feePerKb inSection:feesSection]] withRowAnimation:UITableViewRowAnimationNone];
                self.didChangeFee = YES;
                return;
            }
        }
    } else if ([alertView isEqual:self.errorLoadingAlertView]) {
        // User has tapped on cell when account info has not yet been loaded; get account info again
        [self getAccountInfo];
        return;
    }
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    // Not the smoothest dismissal of the keyboard but better than no animation
    [textField resignFirstResponder];
    
    if (textField.tag == textFieldTagVerifyEmail) {
        [self verifyEmailWithCode:textField.text];
        [self.verifyEmailAlertView dismissWithClickedButtonIndex:0 animated:YES];
    } else if (textField.tag == textFieldTagChangeEmail) {
        // Set delegate to nil, otherwise alertView delegate method will be called and changeEmail will be called twice
        self.changeEmailAlertView.delegate = nil;
        [self changeEmail:textField.text];
        [self.changeEmailAlertView dismissWithClickedButtonIndex:0 animated:YES];
    }
    
    return YES;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"currency"]) {
        SettingsSelectorTableViewController *settingsSelectorTableViewController = segue.destinationViewController;
        settingsSelectorTableViewController.itemsDictionary = self.availableCurrenciesDictionary;
        settingsSelectorTableViewController.allCurrencySymbolsDictionary = self.allCurrencySymbolsDictionary;
        settingsSelectorTableViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:@"about"]) {
        SettingsAboutViewController *aboutViewController = segue.destinationViewController;
        if ([sender isEqualToString:@"termsOfService"]) {
            aboutViewController.urlTargetString = TERMS_OF_SERVICE_URL;
        } else if ([sender isEqualToString:@"privacyPolicy"]) {
            aboutViewController.urlTargetString = PRIVACY_POLICY_URL;
        }
    } else if ([segue.identifier isEqualToString:@"btcUnit"]) {
        SettingsBitcoinUnitTableViewController *settingsBtcUnitTableViewController = segue.destinationViewController;
        settingsBtcUnitTableViewController.itemsDictionary = self.accountInfoDictionary[@"btc_currencies"];
        settingsBtcUnitTableViewController.delegate = self;
    }
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    switch (indexPath.section) {
        case accountDetailsSection: {
            switch (indexPath.row) {
                case accountDetailsEmail: {
                    if (![self hasAddedEmail]) {
                        [self alertViewToChangeEmail:NO];
                    } else if ([self hasVerifiedEmail]) {
                        [self alertViewToChangeEmail:YES];
                    } else {
                        [self alertViewToVerifyEmail];
                    } return;
                }
            }
            return;
        }
        case displaySection: {
            switch (indexPath.row) {
                case displayLocalCurrency: {
                    [self performSegueWithIdentifier:@"currency" sender:nil];
                    return;
                }
                case displayBtcUnit: {
                    [self performSegueWithIdentifier:@"btcUnit" sender:nil];
                    return;
                }
            }
            return;
        }
        case feesSection: {
            switch (indexPath.row) {
                case feePerKb: {
                    [self alertViewToChangeFee];
                    return;
                }
            }
            return;
        }
        case aboutSection: {
            switch (indexPath.row) {
                case aboutTermsOfService: {
                    [self performSegueWithIdentifier:@"about" sender:@"termsOfService"];
                    return;
                }
                case aboutPrivacyPolicy: {
                    [self performSegueWithIdentifier:@"about" sender:@"privacyPolicy"];
                    return;
                }
            }
            return;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case accountDetailsSection: return 2;
        case displaySection: return 2;
        case feesSection: return 1;
        case aboutSection: return 2;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case accountDetailsSection: return BC_STRING_SETTINGS_ACCOUNT_DETAILS;
        case displaySection: return BC_STRING_SETTINGS_DISPLAY_PREFERENCES;
        case feesSection: return BC_STRING_SETTINGS_FEES;
        case aboutSection: return BC_STRING_SETTINGS_ABOUT;
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case accountDetailsSection: return BC_STRING_SETTINGS_EMAIL_FOOTER;
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.font = [SettingsTableViewController fontForCell];
    cell.detailTextLabel.font = [SettingsTableViewController fontForCell];
    
    switch (indexPath.section) {
        case accountDetailsSection: {
            switch (indexPath.row) {
                case accountDetailsIdentifier: {
                    UITableViewCell *cellWithSubtitle = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                    cellWithSubtitle.selectionStyle = UITableViewCellSelectionStyleNone;
                    cellWithSubtitle.textLabel.font = [SettingsTableViewController fontForCell];
                    cellWithSubtitle.textLabel.text = BC_STRING_SETTINGS_WALLET_IDENTIFIER;
                    cellWithSubtitle.detailTextLabel.text = app.wallet.guid;
                    cellWithSubtitle.detailTextLabel.font = [SettingsTableViewController fontForCellSubtitle];
                    cellWithSubtitle.detailTextLabel.textColor = [UIColor grayColor];
                    cellWithSubtitle.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                    return cellWithSubtitle;
                }
                case accountDetailsEmail: {
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    
                    if ([self getUserEmail] != nil && [self.accountInfoDictionary[@"email_verified"] boolValue] == YES) {
                        cell.detailTextLabel.text = [self getUserEmail];
                    } else if ([self hasAddedEmail]) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_EMAIL_UNVERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                    } else {
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_PLEASE_ADD_EMAIL;
                    }
                    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                    return cell;
                }
            }
        }
        case displaySection: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            switch (indexPath.row) {
                case displayLocalCurrency: {
                    NSString *selectedCurrencyCode = [self getLocalSymbolFromLatestResponse].code;
                    NSString *currencyName = self.availableCurrenciesDictionary[selectedCurrencyCode];
                    cell.textLabel.text = BC_STRING_SETTINGS_LOCAL_CURRENCY;
                    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@ (%@)", currencyName, self.allCurrencySymbolsDictionary[selectedCurrencyCode][@"symbol"]];
                    if (currencyName == nil || self.allCurrencySymbolsDictionary[selectedCurrencyCode][@"symbol"] == nil) {
                        cell.detailTextLabel.text = @"";
                    }
                    return cell;
                }
                case displayBtcUnit: {
                    NSString *selectedCurrencyCode = [self getBtcSymbolFromLatestResponse].name;
                    cell.textLabel.text = BC_STRING_SETTINGS_BTC;
                    cell.detailTextLabel.text = selectedCurrencyCode;
                    if (selectedCurrencyCode == nil) {
                        cell.detailTextLabel.text = @"";
                    }
                    return cell;
                }
            }
        }
        case feesSection: {
            switch (indexPath.row) {
                case feePerKb: {
                    cell.textLabel.text = BC_STRING_SETTINGS_FEE_PER_KB;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:BC_STRING_SETTINGS_FEE_ARGUMENT_BTC, [self getFeePerKb]];
                    return cell;
                }
            }
        }
        case aboutSection: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (indexPath.row) {
                case aboutTermsOfService: {
                    cell.textLabel.text = BC_STRING_SETTINGS_TERMS_OF_SERVICE;
                    return cell;
                }
                case aboutPrivacyPolicy: {
                    cell.textLabel.text = BC_STRING_SETTINGS_PRIVACY_POLICY;
                    return cell;
                }
            }
        }        default: return nil;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    BOOL hasLoadedSettings = self.accountInfoDictionary ? YES : NO;
    
    if (!hasLoadedSettings) {
        [self alertViewForErrorLoadingSettings];
        return nil;
    } else {
        return indexPath;
    }
}

@end
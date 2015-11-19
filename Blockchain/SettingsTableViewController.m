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

#ifdef TOUCH_ID_ENABLED
const int securitySection = 3;
const int securityTouchID = 0;

const int aboutSection = 4;
#else
const int securitySection = -1;
const int securityTouchID = -1;

const int aboutSection = 3;
#endif
const int aboutTermsOfService = 0;
const int aboutPrivacyPolicy = 1;

@interface SettingsTableViewController () <CurrencySelectorDelegate, BtcSelectorDelegate, UIAlertViewDelegate, UITextFieldDelegate>

@property (nonatomic, copy) NSDictionary *availableCurrenciesDictionary;
@property (nonatomic, copy) NSDictionary *accountInfoDictionary;
@property (nonatomic, copy) NSDictionary *allCurrencySymbolsDictionary;

@property (nonatomic) UIAlertView *verifyEmailAlertView;
@property (nonatomic) UIAlertView *changeEmailAlertView;
@property (nonatomic) UIAlertView *changeFeeAlertView;

@property (nonatomic, copy) NSString *enteredEmailString;
@property (nonatomic, copy) NSString *emailString;

@property (nonatomic) UITextField *changeFeeTextField;
@property (nonatomic) float currentFeePerKb;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:USER_DEFAULTS_KEY_LOADED_SETTINGS];
    [self reload];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.verifyEmailAlertView dismissWithClickedButtonIndex:0 animated:NO];
    [self.changeEmailAlertView dismissWithClickedButtonIndex:0 animated:NO];
    [self.changeFeeAlertView dismissWithClickedButtonIndex:0 animated:NO];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (app.wallet.isSyncingForCriticalProcess) {
        [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    BOOL loadedSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_LOADED_SETTINGS] boolValue];
    if (!loadedSettings) {
        [self reload];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
#ifdef TOUCH_ID_ENABLED
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:securityTouchID inSection:securitySection];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
#endif
}

- (void)reload
{
    DLog(@"Reloading settings");
    
    [self getAccountInfo];
    [self getAllCurrencySymbols];
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
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:USER_DEFAULTS_KEY_LOADED_SETTINGS];
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

- (NSString *)convertFloatToString:(float)floatNumber
{
    NSNumberFormatter *feePerKbFormatter = [[NSNumberFormatter alloc] init];
    feePerKbFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    feePerKbFormatter.maximumFractionDigits = 8;
    
    return [feePerKbFormatter stringFromNumber:[NSNumber numberWithFloat:floatNumber]];
}

- (void)alertUserToChangeFee
{
    NSString *feePerKbString = [self convertFloatToString:self.currentFeePerKb];
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_SETTINGS_CHANGE_FEE_TITLE message:[[NSString alloc] initWithFormat:BC_STRING_SETTINGS_CHANGE_FEE_MESSAGE_ARGUMENT, feePerKbString] delegate:self cancelButtonTitle:BC_STRING_CANCEL otherButtonTitles:BC_STRING_DONE, nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
    textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
    textField.autocorrectionType = UITextAutocorrectionTypeNo;
    textField.spellCheckingType = UITextSpellCheckingTypeNo;
    textField.text = feePerKbString;
    textField.text = [textField.text stringByReplacingOccurrencesOfString:@"." withString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    textField.keyboardType = UIKeyboardTypeDecimalPad;
    [alertView show];
    textField.delegate = self;
    self.changeFeeTextField = textField;
    self.changeFeeAlertView = alertView;
}

- (void)alertUserOfErrorLoadingSettings
{
    [app standardNotify:BC_STRING_SETTINGS_ERROR_LOADING_MESSAGE title:BC_STRING_SETTINGS_ERROR_LOADING_TITLE delegate:nil];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:USER_DEFAULTS_KEY_LOADED_SETTINGS];
}

- (void)alertUserToChangeEmail:(BOOL)hasAddedEmail
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
    textField.text = hasAddedEmail ? [self getUserEmail] : @"";
    [alertView show];
    self.changeEmailAlertView = alertView;
}

- (void)alertUserToVerifyEmail
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

- (void)alertUserOfVerifyingEmailSuccess
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
    
    [self alertUserToVerifyEmail];
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
    
    dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
    dispatch_after(delayTime, dispatch_get_main_queue(), ^{
        [self alertUserToVerifyEmail];
    });
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
    
    [self performSelector:@selector(alertUserOfVerifyingEmailSuccess) withObject:nil afterDelay:0.2f];
}

- (void)switchTouchIDTapped
{
    if ([app isTouchIDAvailable]) {
        
        BOOL touchIDEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
        
        if (!touchIDEnabled == YES) {
            [app validatePINOptionally];
        } else {
            [app disabledTouchID];
            [[NSUserDefaults standardUserDefaults] setBool:!touchIDEnabled forKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
        }
    } else {
        DLog(@"Touch ID not available on this device!");
    }
}

#pragma mark AlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if ([alertView isEqual:self.changeEmailAlertView]) {
        
        // Not the smoothest dismissal of the keyboard but better than no animation
        BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
        [textField resignFirstResponder];
        
        switch (buttonIndex) {
            case 0: {
                // If the user cancels right after adding a legitimate email address, update the tableView so that it says "Please verify" instead of "Please add"
                UITableViewCell *emailCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:accountDetailsEmail inSection:accountDetailsSection]];
                if (([emailCell.detailTextLabel.text isEqualToString:BC_STRING_SETTINGS_PLEASE_ADD_EMAIL] && [alertView.title isEqualToString:BC_STRING_SETTINGS_CHANGE_EMAIL]) || ![[self getUserEmail] isEqualToString:self.emailString]) {
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
        
        // Not the smoothest dismissal of the keyboard but better than no animation
        BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
        [textField resignFirstResponder];
        
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
                    [self alertUserToChangeEmail:YES];
                });
                return;
            }
        }
        return;
    } else if ([alertView isEqual:self.changeFeeAlertView]) {
        
        // Not the smoothest dismissal of the keyboard but better than no animation
        BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
        [textField resignFirstResponder];
        
        switch (buttonIndex) {
            case 0: {
                return;
            }
            case 1: {
                BCSecureTextField *textField = (BCSecureTextField *)[alertView textFieldAtIndex:0];
                NSString *decimalSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
                NSString *convertedText = [textField.text stringByReplacingOccurrencesOfString:decimalSeparator withString:@"."];
                float fee = [convertedText floatValue];
                if (fee > 0.01) {
                    [app standardNotify:BC_STRING_SETTINGS_FEE_TOO_HIGH];
                    return;
                }
                
                if (fee == 0) {
                    UIAlertController *alertForWarningOfZeroFee = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING_TITLE message:BC_STRING_WARNING_FOR_ZERO_FEE preferredStyle:UIAlertControllerStyleAlert];
                    [alertForWarningOfZeroFee addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
                    [alertForWarningOfZeroFee addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                        NSNumber *unconvertedFee = [NSNumber numberWithFloat:fee * [[NSNumber numberWithInt:SATOSHI] floatValue]];
                        uint64_t convertedFee = (uint64_t)[unconvertedFee longLongValue];
                        [app.wallet setTransactionFee:convertedFee];
                        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:feePerKb inSection:feesSection]] withRowAnimation:UITableViewRowAnimationNone];
                    }]];
                    [self presentViewController:alertForWarningOfZeroFee animated:YES completion:nil];
                    return;
                }
                
                NSNumber *unconvertedFee = [NSNumber numberWithFloat:fee * [[NSNumber numberWithInt:SATOSHI] floatValue]];
                uint64_t convertedFee = (uint64_t)[unconvertedFee longLongValue];
                [app.wallet setTransactionFee:convertedFee];
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:feePerKb inSection:feesSection]] withRowAnimation:UITableViewRowAnimationNone];
                
                return;
            }
        }
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

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.changeFeeTextField) {
        
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray  *points = [newString componentsSeparatedByString:@"."];
        NSArray  *commas = [newString componentsSeparatedByString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
        
        // Only one comma or point in input field allowed
        if ([points count] > 2 || [commas count] > 2)
            return NO;
        
        // Only 1 leading zero
        if (points.count == 1 || commas.count == 1) {
            if (range.location == 1 && ![string isEqualToString:@"."] && ![string isEqualToString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]] && [textField.text isEqualToString:@"0"]) {
                return NO;
            }
        }
        
        NSString *decimalSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
        NSString *numbersWithDecimalSeparatorString = [[NSString alloc] initWithFormat:@"%@%@", NUMBER_KEYPAD_CHARACTER_SET_STRING, decimalSeparator];
        NSCharacterSet *characterSetFromString = [NSCharacterSet characterSetWithCharactersInString:newString];
        NSCharacterSet *numbersAndDecimalCharacterSet = [NSCharacterSet characterSetWithCharactersInString:numbersWithDecimalSeparatorString];
        
        // Only accept numbers and decimal representations
        if (![numbersAndDecimalCharacterSet isSupersetOfSet:characterSetFromString]) {
            return NO;
        }
    }
    
    return YES;
}

#pragma mark - Segue

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_CURRENCY]) {
        SettingsSelectorTableViewController *settingsSelectorTableViewController = segue.destinationViewController;
        settingsSelectorTableViewController.itemsDictionary = self.availableCurrenciesDictionary;
        settingsSelectorTableViewController.allCurrencySymbolsDictionary = self.allCurrencySymbolsDictionary;
        settingsSelectorTableViewController.delegate = self;
    } else if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_ABOUT]) {
        SettingsAboutViewController *aboutViewController = segue.destinationViewController;
        if ([sender isEqualToString:SEGUE_SENDER_TERMS_OF_SERVICE]) {
            aboutViewController.urlTargetString = TERMS_OF_SERVICE_URL;
        } else if ([sender isEqualToString:SEGUE_SENDER_PRIVACY_POLICY]) {
            aboutViewController.urlTargetString = PRIVACY_POLICY_URL;
        }
    } else if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_BTC_UNIT]) {
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
                case accountDetailsIdentifier: {
                    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_COPY_GUID message:BC_STRING_SETTINGS_COPY_GUID_WARNING preferredStyle:UIAlertControllerStyleActionSheet];
                    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:BC_STRING_COPY_TO_CLIPBOARD style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
                        DLog("User confirmed copying GUID");
                        [UIPasteboard generalPasteboard].string = app.wallet.guid;
                    }];
                    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil];
                    [alert addAction:cancelAction];
                    [alert addAction:copyAction];
                    [self presentViewController:alert animated:YES completion:nil];
                    return;
                }
                case accountDetailsEmail: {
                    if (![self hasAddedEmail]) {
                        [self alertUserToChangeEmail:NO];
                    } else if ([self hasVerifiedEmail]) {
                        [self alertUserToChangeEmail:YES];
                    } else {
                        [self alertUserToVerifyEmail];
                    } return;
                }
            }
            return;
        }
        case displaySection: {
            switch (indexPath.row) {
                case displayLocalCurrency: {
                    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_CURRENCY sender:nil];
                    return;
                }
                case displayBtcUnit: {
                    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_BTC_UNIT sender:nil];
                    return;
                }
            }
            return;
        }
        case feesSection: {
            switch (indexPath.row) {
                case feePerKb: {
                    [self alertUserToChangeFee];
                    return;
                }
            }
            return;
        }
        case aboutSection: {
            switch (indexPath.row) {
                case aboutTermsOfService: {
                    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_ABOUT sender:SEGUE_SENDER_TERMS_OF_SERVICE];
                    return;
                }
                case aboutPrivacyPolicy: {
                    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_ABOUT sender:SEGUE_SENDER_PRIVACY_POLICY];
                    return;
                }
            }
            return;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
#ifdef TOUCH_ID_ENABLED
    return 5;
#else
    return 4;
#endif
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case accountDetailsSection: return 2;
        case displaySection: return 2;
        case feesSection: return 1;
        case securitySection: return 1;
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
        case securitySection: return BC_STRING_SETTINGS_SECURITY;
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
                    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:BC_STRING_SETTINGS_FEE_ARGUMENT_BTC, [self convertFloatToString:[self getFeePerKb]]];
                    return cell;
                }
            }
        }
        case securitySection: {
            switch (indexPath.row) {
                case securityTouchID: {
                    cell = [tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER_TOUCH_ID_FOR_PIN];
                    cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE_IDENTIFIER_TOUCH_ID_FOR_PIN];
                    cell.textLabel.font = [SettingsTableViewController fontForCell];
                    cell.textLabel.text = BC_STRING_SETTINGS_SECURITY_USE_TOUCH_ID_AS_PIN;
                    UISwitch *switchForTouchID = [[UISwitch alloc] init];
                    BOOL touchIDEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
                    switchForTouchID.on = touchIDEnabled;
                    [switchForTouchID addTarget:self action:@selector(switchTouchIDTapped) forControlEvents:UIControlEventTouchUpInside];
                    cell.accessoryView = switchForTouchID;
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
    BOOL hasLoadedAccountInfoDictionary = self.accountInfoDictionary ? YES : NO;
    
    if (!hasLoadedAccountInfoDictionary || [[[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_LOADED_SETTINGS] boolValue] == NO) {
        [self alertUserOfErrorLoadingSettings];
        return nil;
    } else {
        return indexPath;
    }
}

@end
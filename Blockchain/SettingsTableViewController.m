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
#import "SecurityCenterViewController.h"
#import "SettingsTwoStepViewController.h"
#import "Blockchain-Swift.h"
#import "AppDelegate.h"

const int textFieldTagChangePasswordHint = 8;
const int textFieldTagVerifyMobileNumber = 7;
const int textFieldTagChangeMobileNumber = 6;
const int textFieldTagVerifyEmail = 5;

const int walletInformationSection = 0;
const int walletInformationIdentifier = 0;

const int preferencesSectionEmailFooter = 1;
const int preferencesEmail = 0;

const int preferencesSectionNotificationsFooter = 2;
const int preferencesMobileNumber = 0;
const int preferencesNotifications = 1;

const int preferencesSectionEnd = 3;
const int displayLocalCurrency = 0;
const int displayBtcUnit = 1;
const int feePerKb = 2;

const int securitySection = 4;
const int securityTwoStep = 0;
const int securityPasswordHint = 1;
const int securityPasswordChange = 2;
const int securityTorBlocking = 3;
const int securityWalletRecoveryPhrase = 4;

const int PINSection = 5;
const int PINChangePIN = 0;
#ifdef TOUCH_ID_ENABLED
const int PINTouchID = 1;
#else
const int PINTouchID = -1;
#endif

const int aboutSection = 6;
const int aboutTermsOfService = 0;
const int aboutPrivacyPolicy = 1;

@interface SettingsTableViewController () <UITextFieldDelegate>

@property (nonatomic, copy) NSDictionary *availableCurrenciesDictionary;
@property (nonatomic, copy) NSDictionary *allCurrencySymbolsDictionary;

@property (nonatomic, copy) NSString *enteredEmailString;
@property (nonatomic, copy) NSString *emailString;

@property (nonatomic, copy) NSString *enteredMobileNumberString;
@property (nonatomic, copy) NSString *mobileNumberString;

@property (nonatomic) UITextField *changeFeeTextField;
@property (nonatomic) float currentFeePerKb;

@property (nonatomic) BOOL isEnablingTwoStepSMS;
@property (nonatomic) BackupNavigationViewController *backupController;

@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:USER_DEFAULTS_KEY_LOADED_SETTINGS];
    [self updateEmailAndMobileStrings];
    [self reload];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NOTIFICATION_KEY_RELOAD_SETTINGS_AND_SECURITY_CENTER object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    if (app.wallet.isSyncing) {
        [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    }
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.isEnablingTwoStepSMS = NO;
    SettingsNavigationController *navigationController = (SettingsNavigationController *)self.navigationController;
    navigationController.headerLabel.text = BC_STRING_SETTINGS;
    BOOL loadedSettings = [[[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_LOADED_SETTINGS] boolValue];
    if (!loadedSettings) {
        [self reload];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
#ifdef TOUCH_ID_ENABLED
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:PINTouchID inSection:PINSection];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
#endif
    [self.tableView reloadData];
}

- (void)reload
{
    DLog(@"Reloading settings");
    
    [self.backupController reload];

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

- (void)getAccountInfo
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateAccountInfo) name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
    
    [app.wallet getAccountInfo];
}

- (void)updateAccountInfo
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:USER_DEFAULTS_KEY_LOADED_SETTINGS];
    
    DLog(@"SettingsTableViewController: gotAccountInfo");
    
    if (app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_CURRENCIES] != nil) {
        self.availableCurrenciesDictionary = app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_CURRENCIES];
    }
    
    [self updateEmailAndMobileStrings];
    
    if ([self.alertTargetViewController isMemberOfClass:[SecurityCenterViewController class]]) {
        SecurityCenterViewController *securityViewController = (SecurityCenterViewController *)self.alertTargetViewController;
        [securityViewController updateUI];
    } else if ([self.alertTargetViewController isMemberOfClass:[SettingsTwoStepViewController class]]) {
        SettingsTwoStepViewController *twoStepViewController = (SettingsTwoStepViewController *)self.alertTargetViewController;
        [twoStepViewController updateUI];
    }
    
    [self reloadTableView];
}

- (void)updateEmailAndMobileStrings
{
    NSString *emailString = app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_EMAIL];
    
    if (emailString != nil) {
        self.emailString = emailString;
    }
    
    NSString *mobileNumberString = app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_SMS_NUMBER];
    
    if (mobileNumberString != nil) {
        self.mobileNumberString = mobileNumberString;
    }
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

- (void)alertUserOfErrorLoadingSettings
{
    UIAlertController *alertForErrorLoading = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_ERROR_LOADING_TITLE message:BC_STRING_SETTINGS_ERROR_LOADING_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
    [alertForErrorLoading addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertForErrorLoading animated:YES completion:nil];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:USER_DEFAULTS_KEY_LOADED_SETTINGS];
}

- (void)alertUserOfSuccess:(NSString *)successMessage
{
    UIAlertController *alertForSuccess = [UIAlertController alertControllerWithTitle:BC_STRING_SUCCESS message:successMessage preferredStyle:UIAlertControllerStyleAlert];
    [alertForSuccess addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForSuccess animated:YES completion:nil];
    } else {
        [self presentViewController:alertForSuccess animated:YES completion:nil];
    }
    
    [self reload];
}

- (void)alertUserOfError:(NSString *)errorMessage
{
    UIAlertController *alertForError = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
    [alertForError addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForError animated:YES completion:nil];
    } else {
        [self presentViewController:alertForError animated:YES completion:nil];
    }
}

#pragma mark - Change Fee per KB

- (float)getFeePerKb
{
    uint64_t unconvertedFee = [app.wallet getTransactionFee];
    float convertedFee = unconvertedFee / [[NSNumber numberWithInt:SATOSHI] floatValue];
    self.currentFeePerKb = convertedFee;
    return convertedFee;
}

- (NSString *)convertFloatToString:(float)floatNumber forDisplay:(BOOL)isForDisplay
{
    NSNumberFormatter *feePerKbFormatter = [[NSNumberFormatter alloc] init];
    feePerKbFormatter.numberStyle = NSNumberFormatterDecimalStyle;
    feePerKbFormatter.maximumFractionDigits = 8;
    NSNumber *amountNumber = [NSNumber numberWithFloat:floatNumber];
    NSString *displayString = [feePerKbFormatter stringFromNumber:amountNumber];
    if (isForDisplay) {
        return displayString;
    } else {
        NSString *decimalSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
        NSString *numbersWithDecimalSeparatorString = [[NSString alloc] initWithFormat:@"%@%@", NUMBER_KEYPAD_CHARACTER_SET_STRING, decimalSeparator];
        NSCharacterSet *characterSetFromString = [NSCharacterSet characterSetWithCharactersInString:displayString];
        NSCharacterSet *numbersAndDecimalCharacterSet = [NSCharacterSet characterSetWithCharactersInString:numbersWithDecimalSeparatorString];
        
        if (![numbersAndDecimalCharacterSet isSupersetOfSet:characterSetFromString]) {
            // Current keypad will not support this character set; return string with known decimal separators "," and "."
            feePerKbFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
            
            if ([decimalSeparator isEqualToString:@"."]) {
                return [feePerKbFormatter stringFromNumber:amountNumber];;
            } else {
                [feePerKbFormatter setDecimalSeparator:decimalSeparator];
                return [feePerKbFormatter stringFromNumber:amountNumber];
            }
        }
        
        return displayString;
    }
}

- (void)alertUserToChangeFee
{
    NSString *feePerKbString = [self convertFloatToString:self.currentFeePerKb forDisplay:NO];
    UIAlertController *alertForChangingFeePerKb = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_CHANGE_FEE_TITLE message:[[NSString alloc] initWithFormat:BC_STRING_SETTINGS_CHANGE_FEE_MESSAGE_ARGUMENT, feePerKbString] preferredStyle:UIAlertControllerStyleAlert];
    [alertForChangingFeePerKb addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        secureTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        secureTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        secureTextField.text = feePerKbString;
        secureTextField.text = [textField.text stringByReplacingOccurrencesOfString:@"." withString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
        secureTextField.keyboardType = UIKeyboardTypeDecimalPad;
        secureTextField.delegate = self;
        self.changeFeeTextField = secureTextField;
    }];
    [alertForChangingFeePerKb addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [alertForChangingFeePerKb addAction:[UIAlertAction actionWithTitle:BC_STRING_DONE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        BCSecureTextField *textField = (BCSecureTextField *)[[alertForChangingFeePerKb textFields] firstObject];
        NSString *decimalSeparator = [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator];
        NSString *convertedText = [textField.text stringByReplacingOccurrencesOfString:decimalSeparator withString:@"."];
        float fee = [convertedText floatValue];
        if (fee > 0.01 || fee == 0) {
            UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:BC_STRING_SETTINGS_ERROR_FEE_OUT_OF_RANGE preferredStyle:UIAlertControllerStyleAlert];
            [errorAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:errorAlert animated:YES completion:nil];
            return;
        }
        
        [self confirmChangeFee:fee];
    }]];
    [self presentViewController:alertForChangingFeePerKb animated:YES completion:nil];
}

- (void)confirmChangeFee:(float)fee
{
    NSNumber *unconvertedFee = [NSNumber numberWithFloat:fee * [[NSNumber numberWithInt:SATOSHI] floatValue]];
    uint64_t convertedFee = (uint64_t)[unconvertedFee longLongValue];
    [app.wallet setTransactionFee:convertedFee];
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:feePerKb inSection:preferencesSectionEnd]] withRowAnimation:UITableViewRowAnimationNone];
    
    SettingsNavigationController *navigationController = (SettingsNavigationController *)self.navigationController;
    [navigationController.busyView fadeIn];
}

#pragma mark - Change Mobile Number

- (NSString *)getMobileNumber
{
    return app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_SMS_NUMBER];
}

- (void)alertUserToChangeMobileNumber
{
    if ([app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_TWO_STEP_TYPE] intValue] == TWO_STEP_AUTH_TYPE_SMS) {
        UIAlertController *alertToDisableTwoFactorSMS = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_ENABLED_ARGUMENT, BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_SMS] message:[NSString stringWithFormat:BC_STRING_SETTINGS_SECURITY_MUST_DISABLE_TWO_FACTOR_SMS_ARGUMENT, self.mobileNumberString] preferredStyle:UIAlertControllerStyleAlert];
        [alertToDisableTwoFactorSMS addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        if (self.alertTargetViewController) {
            [self.alertTargetViewController presentViewController:alertToDisableTwoFactorSMS animated:YES completion:nil];
        } else {
            [self presentViewController:alertToDisableTwoFactorSMS animated:YES completion:nil];
        }
        return;
    }
    
    UIAlertController *alertForChangingMobileNumber = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_CHANGE_MOBILE_NUMBER message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertForChangingMobileNumber addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        self.isEnablingTwoStepSMS = NO;
    }]];
    [alertForChangingMobileNumber addAction:[UIAlertAction actionWithTitle:BC_STRING_SETTINGS_VERIFY style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeMobileNumber:[[alertForChangingMobileNumber textFields] firstObject].text];
    }]];
    [alertForChangingMobileNumber addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        secureTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        secureTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        secureTextField.tag = textFieldTagChangeMobileNumber;
        secureTextField.delegate = self;
        secureTextField.keyboardType = UIKeyboardTypePhonePad;
        secureTextField.returnKeyType = UIReturnKeyDone;
        secureTextField.text = self.mobileNumberString;
    }];
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForChangingMobileNumber animated:YES completion:nil];
    } else {
        [self presentViewController:alertForChangingMobileNumber animated:YES completion:nil];
    }
}

- (void)changeMobileNumber:(NSString *)newNumber
{
    [app.wallet changeMobileNumber:newNumber];
    
    self.enteredMobileNumberString = newNumber;

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMobileNumberSuccess) name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMobileNumberError) name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_ERROR object:nil];
}

- (void)changeMobileNumberSuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_ERROR object:nil];
    
    self.mobileNumberString = self.enteredMobileNumberString;
    
    [self alertUserToVerifyMobileNumber];
}

- (void)changeMobileNumberError
{
    self.isEnablingTwoStepSMS = NO;
    [self alertUserOfError:BC_STRING_SETTINGS_ERROR_INVALID_MOBILE_NUMBER];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_ERROR object:nil];
}

- (void)alertUserToVerifyMobileNumber
{
    UIAlertController *alertForVerifyingMobileNumber = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_VERIFY_ENTER_CODE message:[[NSString alloc] initWithFormat:BC_STRING_SETTINGS_SENT_TO_ARGUMENT, self.mobileNumberString] preferredStyle:UIAlertControllerStyleAlert];
    [alertForVerifyingMobileNumber addAction:[UIAlertAction actionWithTitle:BC_STRING_SETTINGS_VERIFY_MOBILE_RESEND style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeMobileNumber:self.mobileNumberString];
    }]];
    [alertForVerifyingMobileNumber addAction:[UIAlertAction actionWithTitle:BC_STRING_SETTINGS_NEW_MOBILE_NUMBER style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self alertUserToChangeMobileNumber];
    }]];
    [alertForVerifyingMobileNumber addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // If the user cancels right after adding a legitimate number, update accountInfo
        self.isEnablingTwoStepSMS = NO;
        [self getAccountInfo];
    }]];
    [alertForVerifyingMobileNumber addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        secureTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        secureTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        secureTextField.tag = textFieldTagVerifyMobileNumber;
        secureTextField.delegate = self;
        secureTextField.returnKeyType = UIReturnKeyDone;
        secureTextField.placeholder = BC_STRING_ENTER_VERIFICATION_CODE;
    }];
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForVerifyingMobileNumber animated:YES completion:nil];
    } else {
        [self presentViewController:alertForVerifyingMobileNumber animated:YES completion:nil];
    }}

- (void)verifyMobileNumber:(NSString *)code
{
    [app.wallet verifyMobileNumber:code];
    [self addObserversForVerifyingMobileNumber];
    // Mobile number error appears through sendEvent
}

- (void)addObserversForVerifyingMobileNumber
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verifyMobileNumberSuccess) name:NOTIFICATION_KEY_VERIFY_MOBILE_NUMBER_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verifyMobileNumberError) name:NOTIFICATION_KEY_VERIFY_MOBILE_NUMBER_ERROR object:nil];
}

- (void)verifyMobileNumberSuccess
{
    [self removeObserversForVerifyingMobileNumber];
    
    if (self.isEnablingTwoStepSMS) {
        [self enableTwoStepForSMS];
        return;
    }
    
    [self alertUserOfSuccess:BC_STRING_SETTINGS_MOBILE_NUMBER_VERIFIED];
}

- (void)verifyMobileNumberError
{
    [self removeObserversForVerifyingMobileNumber];
    self.isEnablingTwoStepSMS = NO;
}

- (void)removeObserversForVerifyingMobileNumber
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_VERIFY_MOBILE_NUMBER_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_VERIFY_MOBILE_NUMBER_ERROR object:nil];
}

#pragma mark - Change Touch ID

- (void)switchTouchIDTapped
{
    NSString *errorString = [app checkForTouchIDAvailablility];
    if (!errorString) {
        [self toggleTouchID];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
        
        UIAlertController *alertTouchIDError = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:errorString preferredStyle:UIAlertControllerStyleAlert];
        [alertTouchIDError addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:PINTouchID inSection:PINSection];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }]];
        [self presentViewController:alertTouchIDError animated:YES completion:nil];
    }
}

- (void)toggleTouchID
{
    BOOL touchIDEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
    
    if (!touchIDEnabled == YES) {
        UIAlertController *alertForTogglingTouchID = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_SECURITY_USE_TOUCH_ID_AS_PIN message:BC_STRING_TOUCH_ID_WARNING preferredStyle:UIAlertControllerStyleAlert];
        [alertForTogglingTouchID addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:PINTouchID inSection:PINSection];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }]];
        [alertForTogglingTouchID addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [app validatePINOptionally];
        }]];
        [self presentViewController:alertForTogglingTouchID animated:YES completion:nil];
    } else {
        [[NSUserDefaults standardUserDefaults] setBool:!touchIDEnabled forKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
    }
}

#pragma mark - Change email notifications

- (BOOL)notificationsEnabled
{
    NSArray *notificationsType = app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_NOTIFICATIONS_TYPE];
    int notificationsOn = [app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_NOTIFICATIONS_ON] intValue];
    return notificationsType && [notificationsType count] > 0 && [notificationsType containsObject:@1] && (notificationsOn == DICTIONARY_VALUE_NOTIFICATION_SEND_AND_RECEIVE || notificationsOn == DICTIONARY_VALUE_NOTIFICATION_RECEIVE);;
}

- (void)toggleEmailNotifications
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:preferencesNotifications inSection:preferencesSectionNotificationsFooter];
    
    if ([app checkInternetConnection]) {
        if ([self notificationsEnabled]) {
            [app.wallet disableEmailNotifications];
        } else {
            if ([app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_EMAIL_VERIFIED] boolValue] == YES) {
                [app.wallet enableEmailNotifications];
            } else {
                [self alertUserOfError:BC_STRING_PLEASE_VERIFY_EMAIL_ADDRESS_FIRST];
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                return;
            }
        }
        
        UITableViewCell *changeEmailNotificationsCell = [self.tableView cellForRowAtIndexPath:indexPath];
        changeEmailNotificationsCell.userInteractionEnabled = NO;
        [self addObserversForChangingEmailNotifications];
    } else {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }

}

- (void)addObserversForChangingEmailNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeEmailNotificationsSuccess) name:NOTIFICATION_KEY_CHANGE_EMAIL_NOTIFICATIONS_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeEmailNotificationsSuccess) name:NOTIFICATION_KEY_CHANGE_EMAIL_NOTIFICATIONS_ERROR object:nil];
}

- (void)removeObserversForChangingEmailNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_EMAIL_NOTIFICATIONS_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_EMAIL_NOTIFICATIONS_ERROR object:nil];
}

- (void)changeEmailNotificationsSuccess
{
    [self removeObserversForChangingEmailNotifications];
    
    SettingsNavigationController *navigationController = (SettingsNavigationController *)self.navigationController;
    [navigationController.busyView fadeIn];
    
    UITableViewCell *changeEmailNotificationsCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:preferencesNotifications inSection:preferencesNotifications]];
    changeEmailNotificationsCell.userInteractionEnabled = YES;
}

- (void)changeEmailNotificationsError
{
    [self removeObserversForChangingEmailNotifications];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:preferencesNotifications inSection:preferencesNotifications];
    
    UITableViewCell *changeEmailNotificationsCell = [self.tableView cellForRowAtIndexPath:indexPath];
    changeEmailNotificationsCell.userInteractionEnabled = YES;
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

#pragma mark - Change Two Step

- (void)alertUserToChangeTwoStepVerification
{
    NSString *alertTitle;
    BOOL isTwoStepEnabled = YES;
    int twoStepType = [app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_TWO_STEP_TYPE] intValue];
    if (twoStepType == TWO_STEP_AUTH_TYPE_SMS) {
        alertTitle = [NSString stringWithFormat:BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_ENABLED_ARGUMENT, BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_SMS];
    } else if (twoStepType == TWO_STEP_AUTH_TYPE_GOOGLE) {
        alertTitle = [NSString stringWithFormat:BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_ENABLED_ARGUMENT, BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_GOOGLE];
    } else if (twoStepType == TWO_STEP_AUTH_TYPE_YUBI_KEY){
        alertTitle = [NSString stringWithFormat:BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_ENABLED_ARGUMENT, BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_YUBI_KEY];
    } else if (twoStepType == TWO_STEP_AUTH_TYPE_NONE) {
        alertTitle = BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_DISABLED;
        isTwoStepEnabled = NO;
    } else {
        alertTitle = BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_ENABLED;
    }
    
    UIAlertController *alertForChangingTwoStep = [UIAlertController alertControllerWithTitle:alertTitle message:BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_MESSAGE_SMS_ONLY preferredStyle:UIAlertControllerStyleAlert];
    [alertForChangingTwoStep addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler: nil]];
    [alertForChangingTwoStep addAction:[UIAlertAction actionWithTitle:isTwoStepEnabled ? BC_STRING_DISABLE : BC_STRING_ENABLE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeTwoStepVerification];
    }]];
    
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForChangingTwoStep animated:YES completion:nil];
    } else {
        [self presentViewController:alertForChangingTwoStep animated:YES completion:nil];
    }
}

- (void)changeTwoStepVerification
{
    if ([app checkInternetConnection]) {
        
        if ([app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_TWO_STEP_TYPE] intValue] == TWO_STEP_AUTH_TYPE_NONE) {
            self.isEnablingTwoStepSMS = YES;
            if ([app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_SMS_VERIFIED] boolValue] == YES) {
                [self enableTwoStepForSMS];
            } else {
                [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:preferencesMobileNumber inSection:preferencesSectionNotificationsFooter]];
            }
        } else {
            [self disableTwoStep];
        }
    }
}

- (void)enableTwoStepForSMS
{
    [self prepareForForChangingTwoStep];
    [app.wallet enableTwoStepVerificationForSMS];
}

- (void)disableTwoStep
{
    [self prepareForForChangingTwoStep];
    [app.wallet disableTwoStepVerification];
}

- (void)prepareForForChangingTwoStep
{
    UITableViewCell *enableTwoStepCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:securityTwoStep inSection:securitySection]];
    enableTwoStepCell.userInteractionEnabled = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTwoStepSuccess) name:NOTIFICATION_KEY_CHANGE_TWO_STEP_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeTwoStepError) name:NOTIFICATION_KEY_CHANGE_TWO_STEP_ERROR object:nil];
}

- (void)doneChangingTwoStep
{
    UITableViewCell *enableTwoStepCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:securityTwoStep inSection:securitySection]];
    enableTwoStepCell.userInteractionEnabled = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_TWO_STEP_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_TWO_STEP_ERROR object:nil];
}

- (void)changeTwoStepSuccess
{
    if (self.isEnablingTwoStepSMS) {
        [self alertUserOfSuccess:BC_STRING_TWO_STEP_ENABLED_SUCCESS];
    } else {
        [self alertUserOfSuccess:BC_STRING_TWO_STEP_DISABLED_SUCCESS];
    }
    self.isEnablingTwoStepSMS = NO;
    
    [self doneChangingTwoStep];
}

- (void)changeTwoStepError
{
    self.isEnablingTwoStepSMS = NO;
    [self alertUserOfError:BC_STRING_TWO_STEP_ERROR];
    [self doneChangingTwoStep];
    [self getAccountInfo];
}

#pragma mark - Change Email

- (BOOL)hasAddedEmail
{
    return [app.wallet.accountInfo objectForKey:DICTIONARY_KEY_ACCOUNT_SETTINGS_EMAIL] ? YES : NO;
}

- (NSString *)getUserEmail
{
    return [app.wallet.accountInfo objectForKey:DICTIONARY_KEY_ACCOUNT_SETTINGS_EMAIL];
}

- (void)alertUserToChangeEmail:(BOOL)hasAddedEmail
{
    NSString *alertViewTitle = hasAddedEmail ? BC_STRING_SETTINGS_CHANGE_EMAIL :BC_STRING_ADD_EMAIL;
    
    UIAlertController *alertForChangingEmail = [UIAlertController alertControllerWithTitle:alertViewTitle message:BC_STRING_PLEASE_PROVIDE_AN_EMAIL_ADDRESS preferredStyle:UIAlertControllerStyleAlert];
    [alertForChangingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        // If the user cancels right after adding a legitimate email address, update accountInfo
        UITableViewCell *emailCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:preferencesEmail inSection:preferencesSectionEmailFooter]];
        if (([emailCell.detailTextLabel.text isEqualToString:BC_STRING_SETTINGS_UNVERIFIED] && [alertForChangingEmail.title isEqualToString:BC_STRING_SETTINGS_CHANGE_EMAIL]) || ![[self getUserEmail] isEqualToString:self.emailString]) {
            [self getAccountInfo];
        }
    }]];
    [alertForChangingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_SETTINGS_VERIFY style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeEmail:[[alertForChangingEmail textFields] firstObject].text];
    }]];
    [alertForChangingEmail addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        secureTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        secureTextField.returnKeyType = UIReturnKeyDone;
        secureTextField.text = hasAddedEmail ? [self getUserEmail] : @"";
    }];
    
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForChangingEmail animated:YES completion:nil];
    } else {
        [self presentViewController:alertForChangingEmail animated:YES completion:nil];
    }
}

- (void)alertUserToVerifyEmail
{
    UIAlertController *alertForVerifyingEmail = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_VERIFY_ENTER_CODE message:[[NSString alloc] initWithFormat:BC_STRING_SETTINGS_SENT_TO_ARGUMENT, self.emailString] preferredStyle:UIAlertControllerStyleAlert];
    [alertForVerifyingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_SETTINGS_VERIFY_EMAIL_RESEND style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self resendVerificationEmail];
    }]];
    [alertForVerifyingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_SETTINGS_NEW_EMAIL_ADDRESS style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        // Give time for the alertView to fully dismiss, otherwise its keyboard will pop up if entered email is invalid
        dispatch_time_t delayTime = dispatch_time(DISPATCH_TIME_NOW, 0.5f * NSEC_PER_SEC);
        dispatch_after(delayTime, dispatch_get_main_queue(), ^{
            [self alertUserToChangeEmail:YES];
        });
    }]];
    [alertForVerifyingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self getAccountInfo];
    }]];
    [alertForVerifyingEmail addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        secureTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        secureTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        secureTextField.tag = textFieldTagVerifyEmail;
        secureTextField.delegate = self;
        secureTextField.returnKeyType = UIReturnKeyDone;
        secureTextField.placeholder = BC_STRING_ENTER_VERIFICATION_CODE;
    }];
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForVerifyingEmail animated:YES completion:nil];
    } else {
        [self presentViewController:alertForVerifyingEmail animated:YES completion:nil];
    }}

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(verifyEmailWithCodeError) name:NOTIFICATION_KEY_VERIFY_EMAIL_ERROR object:nil];
    
    [app.wallet verifyEmailWithCode:codeString];
}

- (void)verifyEmailWithCodeSuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_VERIFY_EMAIL_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_VERIFY_EMAIL_ERROR object:nil];
    
    [self getAccountInfo];
    
    [self alertUserOfSuccess:BC_STRING_SETTINGS_EMAIL_VERIFIED];
}

- (void)verifyEmailWithCodeError
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_VERIFY_EMAIL_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_VERIFY_EMAIL_ERROR object:nil];
    
    [self alertUserOfError:BC_STRING_SETTINGS_VERIFY_INVALID_CODE];
}

#pragma mark - Change Password Hint

- (void)alertUserToChangePasswordHint
{
    UIAlertController *alertForChangingPasswordHint = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_SECURITY_CHANGE_PASSWORD_HINT message:BC_STRING_HINT_DESCRIPTION preferredStyle:UIAlertControllerStyleAlert];
    [alertForChangingPasswordHint addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [alertForChangingPasswordHint addAction:[UIAlertAction actionWithTitle:BC_STRING_UPDATE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *passwordHint = [[alertForChangingPasswordHint textFields] firstObject].text;
        if ([[passwordHint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] || !passwordHint) {
            [self alertUserThatAllWhiteSpaceCharactersClearsHint];
        } else {
            if ([self isHintValid:passwordHint]) {
                [self changePasswordHint:passwordHint];
            }
        }
    }]];
    NSString *passwordHint = app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_PASSWORD_HINT];
    [alertForChangingPasswordHint addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        secureTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        secureTextField.tag = textFieldTagChangePasswordHint;
        secureTextField.returnKeyType = UIReturnKeyDone;
        secureTextField.text = passwordHint;
    }];
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForChangingPasswordHint animated:YES completion:nil];
    } else {
        [self presentViewController:alertForChangingPasswordHint animated:YES completion:nil];
    };
}

- (void)alertUserThatAllWhiteSpaceCharactersClearsHint
{
    UIAlertController *alertForClearingPasswordHint = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_SECURITY_CHANGE_PASSWORD_HINT message:BC_STRING_SETTINGS_SECURITY_CHANGE_PASSWORD_HINT_WARNING_ALL_WHITESPACE preferredStyle:UIAlertControllerStyleAlert];
    [alertForClearingPasswordHint addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [alertForClearingPasswordHint addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changePasswordHint:@""];
    }]];
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForClearingPasswordHint animated:YES completion:nil];
    } else {
        [self presentViewController:alertForClearingPasswordHint animated:YES completion:nil];
    }
}

- (void)changePasswordHint:(NSString *)hint
{
    UITableViewCell *changePasswordHintCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:securityPasswordHint inSection:securitySection]];
    changePasswordHintCell.userInteractionEnabled = NO;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePasswordHintSuccess) name:NOTIFICATION_KEY_CHANGE_PASSWORD_HINT_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changePasswordHintError) name:NOTIFICATION_KEY_CHANGE_PASSWORD_HINT_ERROR object:nil];
    [app.wallet updatePasswordHint:hint];
}

- (BOOL)isHintValid:(NSString *)hint
{
    if ([app.wallet isCorrectPassword:hint]) {
        [self alertUserOfError:BC_STRING_SETTINGS_SECURITY_CHANGE_PASSWORD_HINT_ERROR_SAME_AS_PASSWORD];
        return NO;
    } else if ([app.wallet validateSecondPassword:hint]) {
        [self alertUserOfError:BC_STRING_SETTINGS_SECURITY_CHANGE_PASSWORD_HINT_ERROR_SAME_AS_SECOND_PASSWORD];
        return NO;
    }
    return YES;
}

- (void)changePasswordHintSuccess
{
    [self resetPasswordHintCell];
    [self alertUserOfSuccess:BC_STRING_SETTINGS_SECURITY_CHANGE_PASSWORD_HINT_SUCCESS];
}

- (void)changePasswordHintError
{
    [self resetPasswordHintCell];
    [self alertUserOfError:BC_STRING_SETTINGS_SECURITY_CHANGE_PASSWORD_HINT_ERROR_INVALID_CHARACTERS];
}

- (void)resetPasswordHintCell
{
    UITableViewCell *changePasswordHintCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:securityPasswordHint inSection:securitySection]];
    changePasswordHintCell.userInteractionEnabled = YES;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_PASSWORD_HINT_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_PASSWORD_HINT_ERROR object:nil];
}

#pragma mark - Change Tor Blocking

- (void)changeTorBlockingTapped
{
    BOOL torBlockingEnabled = [app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_TOR_BLOCKING] boolValue];
    NSString *alertTitle;
    NSString *alertActionTitle;
    if (torBlockingEnabled == YES) {
        alertTitle = BC_STRING_SETTINGS_SECURITY_TOR_REQUESTS_BLOCKED;
        alertActionTitle = BC_STRING_ALLOW;
    } else {
        alertTitle = BC_STRING_SETTINGS_SECURITY_TOR_REQUESTS_ALLOWED;
        alertActionTitle = BC_STRING_BLOCK;
    }
    
    UIAlertController *alertForChangingTorBlocking = [UIAlertController alertControllerWithTitle:alertTitle message:BC_STRING_SETTINGS_SECURITY_TOR_BLOCKING_DESCRIPTION preferredStyle:UIAlertControllerStyleAlert];
    [alertForChangingTorBlocking addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:securityTorBlocking inSection:securitySection];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [alertForChangingTorBlocking addAction:[UIAlertAction actionWithTitle:alertActionTitle style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self updateTorBlocking:!torBlockingEnabled];
    }]];
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForChangingTorBlocking animated:YES completion:nil];
    } else {
        [self presentViewController:alertForChangingTorBlocking animated:YES completion:nil];
    }}

- (void)updateTorBlocking:(BOOL)willEnable
{
    if ([app checkInternetConnection]) {
        [app.wallet changeTorBlocking:willEnable];
        [self addObserversForUpdatingTorBlocking];
    }
}

- (void)updateTorSuccess
{
    [self removeObserversForUpdatingTorBlocking];
    if ([app.wallet hasBlockedTorRequests]) {
        [self alertUserOfSuccess:BC_STRING_TOR_ALLOWED];
    } else {
        [self alertUserOfSuccess:BC_STRING_TOR_BLOCKED];
    }
}

- (void)updateTorError
{
    [self removeObserversForUpdatingTorBlocking];
}

- (void)addObserversForUpdatingTorBlocking
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTorSuccess) name:NOTIFICATION_KEY_CHANGE_TOR_BLOCKING_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(updateTorError) name:NOTIFICATION_KEY_CHANGE_TOR_BLOCKING_ERROR object:nil];
}

- (void)removeObserversForUpdatingTorBlocking
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_TOR_BLOCKING_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_TOR_BLOCKING_ERROR object:nil];
}

#pragma mark - Wallet Recovery Phrase

- (void)showBackup
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

#pragma mark - Change Password

- (void)changePassword
{
    [self performSegueWithIdentifier:@"changePassword" sender:nil];
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    __weak SettingsTableViewController *weakSelf = self;
    
    if (self.alertTargetViewController) {
        [self.alertTargetViewController dismissViewControllerAnimated:YES completion:^{
            if (textField.tag == textFieldTagVerifyEmail) {
                [weakSelf verifyEmailWithCode:textField.text];
                
            } else if (textField.tag == textFieldTagVerifyMobileNumber) {
                [weakSelf verifyMobileNumber:textField.text];
                
            } else if (textField.tag == textFieldTagChangeMobileNumber) {
                [weakSelf changeMobileNumber:textField.text];
            }
        }];
        return YES;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (textField.tag == textFieldTagVerifyEmail) {
            [weakSelf verifyEmailWithCode:textField.text];
            
        } else if (textField.tag == textFieldTagVerifyMobileNumber) {
            [weakSelf verifyMobileNumber:textField.text];
            
        } else if (textField.tag == textFieldTagChangeMobileNumber) {
            [weakSelf changeMobileNumber:textField.text];
        }
    }];

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
    } else if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_ABOUT]) {
        SettingsAboutViewController *aboutViewController = segue.destinationViewController;
        if ([sender isEqualToString:SEGUE_SENDER_TERMS_OF_SERVICE]) {
            aboutViewController.urlTargetString = [[app serverURL] stringByAppendingString:TERMS_OF_SERVICE_URL_SUFFIX];
        } else if ([sender isEqualToString:SEGUE_SENDER_PRIVACY_POLICY]) {
            aboutViewController.urlTargetString = [[app serverURL] stringByAppendingString:PRIVACY_POLICY_URL_SUFFIX];
        }
    } else if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_BTC_UNIT]) {
        SettingsBitcoinUnitTableViewController *settingsBtcUnitTableViewController = segue.destinationViewController;
        settingsBtcUnitTableViewController.itemsDictionary = app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_BTC_CURRENCIES];
    } else if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_TWO_STEP]) {
        SettingsTwoStepViewController *twoStepViewController = (SettingsTwoStepViewController *)segue.destinationViewController;
        twoStepViewController.settingsController = self;
        self.alertTargetViewController = twoStepViewController;
    }
}

#pragma mark - Table view data source

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    switch (indexPath.section) {
        case walletInformationSection: {
            switch (indexPath.row) {
                case walletInformationIdentifier: {
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
            }
            return;
        }
        case preferencesSectionEmailFooter: {
            switch (indexPath.row) {
                case preferencesEmail: {
                    if (![self hasAddedEmail]) {
                        [self alertUserToChangeEmail:NO];
                    } else if ([app.wallet hasVerifiedEmail]) {
                        [self alertUserToChangeEmail:YES];
                    } else {
                        [self alertUserToVerifyEmail];
                    } return;
                }
            }
            return;
        }
        case preferencesSectionNotificationsFooter: {
            switch (indexPath.row) {
                case preferencesMobileNumber: {
                    if ([app.wallet.accountInfo objectForKey:DICTIONARY_KEY_ACCOUNT_SETTINGS_SMS_NUMBER]) {
                        if ([app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_SMS_VERIFIED] boolValue] == YES) {
                            [self alertUserToChangeMobileNumber];
                        } else {
                            [self alertUserToVerifyMobileNumber];
                        }
                    } else {
                        [self alertUserToChangeMobileNumber];
                    }
                    return;
                }
            }
            return;
        }
        case preferencesSectionEnd: {
            switch (indexPath.row) {
                case displayLocalCurrency: {
                    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_CURRENCY sender:nil];
                    return;
                }
                case displayBtcUnit: {
                    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_BTC_UNIT sender:nil];
                    return;
                }
                case feePerKb: {
                    [self alertUserToChangeFee];
                    return;
                }
            }
        }
        case securitySection: {
            if (indexPath.row == securityTwoStep) {
                [self performSegueWithIdentifier:SEGUE_IDENTIFIER_TWO_STEP sender:nil];
                return;
            } else if (indexPath.row == securityPasswordHint) {
                [self alertUserToChangePasswordHint];
                return;
            } else if (indexPath.row == securityPasswordChange) {
                [self changePassword];
                return;
            } else if (indexPath.row == securityTorBlocking) {
                [self changeTorBlockingTapped];
                return;
            } else if (indexPath.row == securityWalletRecoveryPhrase) {
                [self showBackup];
                return;
            }
            return;
        }
        case PINSection: {
            switch (indexPath.row) {
                case PINChangePIN: {
                    [app changePIN];
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
    return 7;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case walletInformationSection: return 1;
        case preferencesSectionEmailFooter: return 1;
        case preferencesSectionNotificationsFooter: return 2;
        case preferencesSectionEnd: return 3;
        case securitySection: return [app.wallet didUpgradeToHd] ? 5 : 4;
        case PINSection: return PINTouchID < 0 ? 1 : 2;
        case aboutSection: return 2;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case walletInformationSection: return BC_STRING_SETTINGS_WALLET_INFORMATION;
        case preferencesSectionEmailFooter: return BC_STRING_SETTINGS_PREFERENCES;
        case preferencesSectionNotificationsFooter: return nil;
        case preferencesSectionEnd: return nil;
        case securitySection: return BC_STRING_SETTINGS_SECURITY;
        case PINSection: return BC_STRING_PIN;
        case aboutSection: return BC_STRING_SETTINGS_ABOUT;
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case preferencesSectionEmailFooter: return BC_STRING_SETTINGS_EMAIL_FOOTER;
        case preferencesSectionNotificationsFooter: return BC_STRING_SETTINGS_NOTIFICATIONS_FOOTER;
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.font = [SettingsTableViewController fontForCell];
    cell.detailTextLabel.font = [SettingsTableViewController fontForCell];
    cell.textLabel.adjustsFontSizeToFitWidth = YES;
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    
    switch (indexPath.section) {
        case walletInformationSection: {
            switch (indexPath.row) {
                case walletInformationIdentifier: {
                    UITableViewCell *cellWithSubtitle = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                    cellWithSubtitle.textLabel.font = [SettingsTableViewController fontForCell];
                    cellWithSubtitle.textLabel.text = BC_STRING_SETTINGS_WALLET_ID;
                    cellWithSubtitle.detailTextLabel.text = app.wallet.guid;
                    cellWithSubtitle.detailTextLabel.font = [SettingsTableViewController fontForCellSubtitle];
                    cellWithSubtitle.detailTextLabel.textColor = [UIColor grayColor];
                    cellWithSubtitle.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                    return cellWithSubtitle;
                }
            }
        }
        case preferencesSectionEmailFooter: {
            switch (indexPath.row) {
                case preferencesEmail: {
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    
                    if ([self getUserEmail] != nil && [app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_EMAIL_VERIFIED] boolValue] == YES) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_VERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_GREEN;
                    } else {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_UNVERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                    }
                    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                    return cell;
                }
            }
        }
        case preferencesSectionNotificationsFooter: {
            switch (indexPath.row) {
                case preferencesMobileNumber: {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    cell.textLabel.text = BC_STRING_SETTINGS_MOBILE_NUMBER;
                    if ([app.wallet hasVerifiedMobileNumber]) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_VERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_GREEN;
                    } else {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_UNVERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    return cell;
                }
                case preferencesNotifications: {
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL_NOTIFICATIONS;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    UISwitch *switchForEmailNotifications = [[UISwitch alloc] init];
                    switchForEmailNotifications.on = [self notificationsEnabled];
                    [switchForEmailNotifications addTarget:self action:@selector(toggleEmailNotifications) forControlEvents:UIControlEventTouchUpInside];
                    cell.accessoryView = switchForEmailNotifications;
                    return cell;
                }
            }
        }
        case preferencesSectionEnd: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
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
                case feePerKb: {
                    cell.textLabel.text = BC_STRING_SETTINGS_FEE_PER_KB;
                    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:BC_STRING_SETTINGS_FEE_ARGUMENT_BTC, [self convertFloatToString:[self getFeePerKb] forDisplay:YES]];
                    return cell;
                }
            }
        }
        case securitySection: {
            if (indexPath.row == securityTwoStep) {
                    cell.textLabel.text = BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    int authType = [app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_TWO_STEP_TYPE] intValue];
                    cell.detailTextLabel.textColor = COLOR_BUTTON_GREEN;
                    if (authType == TWO_STEP_AUTH_TYPE_SMS) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_SMS;
                    } else if (authType == TWO_STEP_AUTH_TYPE_GOOGLE) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_GOOGLE;
                    } else if (authType == TWO_STEP_AUTH_TYPE_YUBI_KEY) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION_YUBI_KEY;
                    } else if (authType == TWO_STEP_AUTH_TYPE_NONE) {
                        cell.detailTextLabel.text = BC_STRING_DISABLED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                    } else {
                        cell.detailTextLabel.text = BC_STRING_UNKNOWN;
                    }
                    return cell;
                }
            else if (indexPath.row == securityPasswordHint) {
                    cell.textLabel.text = BC_STRING_SETTINGS_SECURITY_PASSWORD_HINT;
                    if ([app.wallet hasStoredPasswordHint]) {
                        cell.detailTextLabel.textColor = COLOR_BUTTON_GREEN;
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_STORED;
                    } else {
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_NOT_STORED;
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    return cell;
                }
            else if (indexPath.row == securityPasswordChange) {
                    cell.textLabel.text = BC_STRING_SETTINGS_SECURITY_CHANGE_PASSWORD;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    return cell;
                }
            else if (indexPath.row == securityTorBlocking) {
                    cell.textLabel.font = [SettingsTableViewController fontForCell];
                    cell.textLabel.text = BC_STRING_SETTINGS_SECURITY_TOR_REQUESTS;
                    BOOL torBlockingEnabled = [app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_TOR_BLOCKING] boolValue];
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    if (torBlockingEnabled) {
                        cell.detailTextLabel.textColor = COLOR_BUTTON_GREEN;
                        cell.detailTextLabel.text = BC_STRING_BLOCKED;
                    } else {
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                        cell.detailTextLabel.text = BC_STRING_ALLOWED;
                    }
                    return cell;
                }
            else if (indexPath.row == securityWalletRecoveryPhrase) {
                    cell.textLabel.font = [SettingsTableViewController fontForCell];
                    cell.textLabel.text = BC_STRING_WALLET_RECOVERY_PHRASE;
                    if (app.wallet.isRecoveryPhraseVerified) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_VERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_GREEN;
                    } else {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_UNCONFIRMED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    return cell;
                }
        }
        case PINSection: {
            if (indexPath.row == PINChangePIN) {
                cell.textLabel.text = BC_STRING_CHANGE_PIN;
                cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                return cell;
            }
            if (indexPath.row == PINTouchID) {
                cell = [tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER_TOUCH_ID_FOR_PIN];
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE_IDENTIFIER_TOUCH_ID_FOR_PIN];
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
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
    if (indexPath.section == walletInformationSection && indexPath.row == walletInformationIdentifier) {
        return indexPath;
    }
    
    BOOL hasLoadedAccountInfoDictionary = app.wallet.accountInfo ? YES : NO;
    
    if (!hasLoadedAccountInfoDictionary || [[[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_LOADED_SETTINGS] boolValue] == NO) {
        [self alertUserOfErrorLoadingSettings];
        return nil;
    } else {
        return indexPath;
    }
}

#pragma mark Security Center Helpers

- (void)verifyEmailTapped
{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:preferencesEmail inSection:preferencesSectionEmailFooter]];
}

- (void)linkMobileTapped
{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:preferencesMobileNumber inSection:preferencesSectionNotificationsFooter]];
}

- (void)storeHintTapped
{
    [self tableView:self.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:securityPasswordHint inSection:securitySection]];
}

- (void)changeTwoStepTapped
{
    [self alertUserToChangeTwoStepVerification];
}

- (void)blockTorTapped
{
    [self changeTorBlockingTapped];
}

@end
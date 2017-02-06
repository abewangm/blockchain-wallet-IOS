//
//  SettingsTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/13/15.
//  Copyright (c) 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "SettingsSelectorTableViewController.h"
#import "SettingsWebViewController.h"
#import "SettingsBitcoinUnitTableViewController.h"
#import "SettingsTwoStepViewController.h"
#import "Blockchain-Swift.h"
#import "RootService.h"
#import "KeychainItemWrapper+SwipeAddresses.h"
#import "SettingsAboutUsViewController.h"

const int textFieldTagChangePasswordHint = 8;
const int textFieldTagVerifyMobileNumber = 7;
const int textFieldTagChangeMobileNumber = 6;

const int walletInformationSection = 0;
const int walletInformationIdentifier = 0;

const int preferencesSectionEmailFooter = 1;
const int preferencesEmail = 0;

const int preferencesSectionSMSFooter = 2;
const int preferencesMobileNumber = 0;

const int preferencesSectionNotificationsFooter = 3;
const int preferencesEmailNotifications = 0;
const int preferencesSMSNotifications = 1;

const int preferencesSectionEnd = 4;
const int displayLocalCurrency = 0;
const int displayBtcUnit = 1;

const int securitySection = 5;
const int securityTwoStep = 0;
const int securityPasswordChange = 1;
const int securityWalletRecoveryPhrase = 2;

const int PINSection = 6;
const int PINChangePIN = 0;
#if defined(ENABLE_TOUCH_ID) && defined(ENABLE_SWIPE_TO_RECEIVE)
const int PINTouchID = 1;
const int PINSwipeToReceive = 2;
#elif ENABLE_TOUCH_ID
const int PINTouchID = 1;
const int PINSwipeToReceive = -1;
#elif ENABLE_SWIPE_TO_RECEIVE
const int PINSwipeToReceive = 1;
const int PINTouchID = -1;
#endif

const int aboutSection = 7;
const int aboutUs = 0;
const int aboutTermsOfService = 1;
const int aboutPrivacyPolicy = 2;

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
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadAfterMultiAddressResponse) name:NOTIFICATION_KEY_RELOAD_SETTINGS_AND_SECURITY_CENTER_AFTER_MULTIADDRESS object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
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
    [self.tableView reloadData];
}

- (void)reload
{
    DLog(@"Reloading settings");
    
    [self.backupController reload];

    [self getAccountInfo];
    [self getAllCurrencySymbols];
}

- (void)reloadAfterMultiAddressResponse
{
    [self.backupController reload];

    [self updateAccountInfo];
    [self updateCurrencySymbols];
}

- (void)getAllCurrencySymbols
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didGetCurrencySymbols) name:NOTIFICATION_KEY_GET_ALL_CURRENCY_SYMBOLS_SUCCESS object:nil];
    
    [app.wallet getAllCurrencySymbols];
}

- (void)didGetCurrencySymbols
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_GET_ALL_CURRENCY_SYMBOLS_SUCCESS object:nil];
    [self updateCurrencySymbols];
}

- (void)updateCurrencySymbols
{
    self.allCurrencySymbolsDictionary = app.wallet.currencySymbols;
    
    [self reloadTableView];
}

- (void)getAccountInfo
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didGetAccountInfo) name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
    
    [app.wallet getAccountInfo];
}

- (void)didGetAccountInfo
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
    [self updateAccountInfo];
}

- (void)updateAccountInfo
{
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:USER_DEFAULTS_KEY_LOADED_SETTINGS];
    
    DLog(@"SettingsTableViewController: gotAccountInfo");
    
    if ([app.wallet getFiatCurrencies] != nil) {
        self.availableCurrenciesDictionary = [app.wallet getFiatCurrencies];
    }
    
    [self updateEmailAndMobileStrings];
    
    if ([self.alertTargetViewController isMemberOfClass:[SettingsTwoStepViewController class]]) {
        SettingsTwoStepViewController *twoStepViewController = (SettingsTwoStepViewController *)self.alertTargetViewController;
        [twoStepViewController updateUI];
    }
    
    [self reloadTableView];
}

- (void)updateEmailAndMobileStrings
{
    NSString *emailString = [app.wallet getEmail];
    
    if (emailString != nil) {
        self.emailString = emailString;
    }
    
    NSString *mobileNumberString = [app.wallet getSMSNumber];
    
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
    return [UIFont fontWithName:FONT_HELVETICA_NUEUE size:15];
}

+ (UIFont *)fontForCellSubtitle
{
    return [UIFont fontWithName:FONT_HELVETICA_NUEUE size:12];
}



- (UITableViewCell *)adjustFontForCell:(UITableViewCell *)cell
{
    UILabel *cellTextLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    cellTextLabel.text = cell.textLabel.text;
    [cellTextLabel sizeToFit];
    if (cellTextLabel.frame.size.width > cell.contentView.frame.size.width * 2/3) {
        cell.textLabel.font = [UIFont fontWithName:FONT_HELVETICA_NUEUE size:12];
        cell.detailTextLabel.font = [UIFont fontWithName:FONT_HELVETICA_NUEUE size:12];
    }
    
    if (cellTextLabel.frame.size.width > cell.contentView.frame.size.width * 4/5) {
        cell.textLabel.font = [UIFont fontWithName:FONT_HELVETICA_NUEUE size:10];
        cell.detailTextLabel.font = [UIFont fontWithName:FONT_HELVETICA_NUEUE size:10];
    }
    
    return cell;
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

#pragma mark - Actions

- (void)walletIdentifierClicked
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_COPY_GUID message:BC_STRING_SETTINGS_COPY_GUID_WARNING preferredStyle:UIAlertControllerStyleActionSheet];
    UIAlertAction *copyAction = [UIAlertAction actionWithTitle:BC_STRING_COPY_TO_CLIPBOARD style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        DLog("User confirmed copying GUID");
        [UIPasteboard generalPasteboard].string = app.wallet.guid;
    }];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil];
    [alert addAction:cancelAction];
    [alert addAction:copyAction];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)emailClicked
{
    if (![self hasAddedEmail]) {
        [self alertUserToChangeEmail:NO];
    } else if ([app.wallet hasVerifiedEmail]) {
        [self alertUserToChangeEmail:YES];
    } else {
        [self alertUserToVerifyEmail];
    }
}

- (void)mobileNumberClicked
{
    if ([app.wallet getSMSNumber].length > 0) {
        if ([app.wallet getSMSVerifiedStatus] == YES) {
            [self alertUserToChangeMobileNumber];
        } else {
            [self alertUserToVerifyMobileNumber];
        }
    } else {
        [self alertUserToChangeMobileNumber];
    }
}

- (void)aboutUsClicked
{
    SettingsAboutUsViewController *aboutViewController = [[SettingsAboutUsViewController alloc] init];
    BCNavigationController *navigationController = [[BCNavigationController alloc] initWithRootViewController:aboutViewController title:nil];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)termsOfServiceClicked
{
    SettingsWebViewController *aboutViewController = [[SettingsWebViewController alloc] init];
    aboutViewController.urlTargetString = [URL_SERVER stringByAppendingString:URL_SUFFIX_TERMS_OF_SERVICE];
    BCNavigationController *navigationController = [[BCNavigationController alloc] initWithRootViewController:aboutViewController title:BC_STRING_SETTINGS_TERMS_OF_SERVICE];
    [self presentViewController:navigationController animated:YES completion:nil];
}

- (void)showPrivacyPolicy
{
    SettingsWebViewController *aboutViewController = [[SettingsWebViewController alloc] init];
    aboutViewController.urlTargetString = [URL_SERVER stringByAppendingString:URL_SUFFIX_PRIVACY_POLICY];
    BCNavigationController *navigationController = [[BCNavigationController alloc] initWithRootViewController:aboutViewController title:BC_STRING_SETTINGS_PRIVACY_POLICY];
    [self presentViewController:navigationController animated:YES completion:nil];
}

#pragma mark - Change Fee per KB

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
            feePerKbFormatter.locale = [NSLocale localeWithLocaleIdentifier:LOCALE_IDENTIFIER_EN_US];
            
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

#pragma mark - Change Mobile Number

- (NSString *)getMobileNumber
{
    return [app.wallet getSMSNumber];
}

- (void)alertUserToChangeMobileNumber
{
    if ([app.wallet getTwoStepType] == TWO_STEP_AUTH_TYPE_SMS) {
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
    self.enteredMobileNumberString = newNumber;
    
    if ([app.wallet SMSNotificationsEnabled]) {
        [self alertUserAboutDisablingSMSNotifications:newNumber];
    } else {
        [app.wallet changeMobileNumber:newNumber];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMobileNumberSuccess) name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_SUCCESS object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMobileNumberError) name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_ERROR object:nil];
    }
}

- (void)alertUserAboutDisablingSMSNotifications:(NSString *)newNumber
{
    UIAlertController *alertForChangingEmail = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_NEW_MOBILE_NUMBER message:BC_STRING_SETTINGS_NEW_MOBILE_NUMBER_WARNING_DISABLE_NOTIFICATIONS preferredStyle:UIAlertControllerStyleAlert];
    [alertForChangingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [alertForChangingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self disableNotificationsThenChangeMobileNumber:newNumber];
    }]];
    
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForChangingEmail animated:YES completion:nil];
    } else {
        [self presentViewController:alertForChangingEmail animated:YES completion:nil];
    }
}

- (void)disableNotificationsThenChangeMobileNumber:(NSString *)newNumber
{
    SettingsNavigationController *navigationController = (SettingsNavigationController *)self.navigationController;
    [navigationController.busyView fadeIn];
    
    [app.wallet disableSMSNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMobileNumberAfterDisablingNotifications) name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
}

- (void)changeMobileNumberAfterDisablingNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
    
    [app.wallet changeMobileNumber:self.enteredMobileNumberString];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMobileNumberSuccess) name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeMobileNumberError) name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_ERROR object:nil];
}

- (void)changeMobileNumberSuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_ERROR object:nil];
    
    self.mobileNumberString = self.enteredMobileNumberString;
    
    [self getAccountInfo];
    
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

#pragma mark - Change Swipe to Receive

- (void)switchSwipeToReceiveTapped
{
    BOOL swipeToReceiveEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_SWIPE_TO_RECEIVE_ENABLED];
    [[NSUserDefaults standardUserDefaults] setBool:!swipeToReceiveEnabled forKey:USER_DEFAULTS_KEY_SWIPE_TO_RECEIVE_ENABLED];
    
    // Clear all swipe addresses in case default account has changed
    if (!swipeToReceiveEnabled) [KeychainItemWrapper removeAllSwipeAddresses];
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
    
    if (!(touchIDEnabled == YES)) {
        UIAlertController *alertForTogglingTouchID = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_PIN_USE_TOUCH_ID_AS_PIN message:BC_STRING_TOUCH_ID_WARNING preferredStyle:UIAlertControllerStyleAlert];
        [alertForTogglingTouchID addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            NSIndexPath *indexPath = [NSIndexPath indexPathForRow:PINTouchID inSection:PINSection];
            [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
        }]];
        [alertForTogglingTouchID addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [app validatePINOptionally];
        }]];
        [self presentViewController:alertForTogglingTouchID animated:YES completion:nil];
    } else {
        [app disabledTouchID];
        [[NSUserDefaults standardUserDefaults] setBool:!touchIDEnabled forKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
    }
}

#pragma mark - Change notifications

- (BOOL)emailNotificationsEnabled
{
    return [app.wallet emailNotificationsEnabled];
}

- (BOOL)SMSNotificationsEnabled
{
    return [app.wallet SMSNotificationsEnabled];
}

- (void)toggleEmailNotifications
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:preferencesEmailNotifications inSection:preferencesSectionNotificationsFooter];
    
    if ([app checkInternetConnection]) {
        if ([self emailNotificationsEnabled]) {
            [app.wallet disableEmailNotifications];
        } else {
            if ([app.wallet getEmailVerifiedStatus] == YES) {
                [app.wallet enableEmailNotifications];
            } else {
                [self alertUserOfError:BC_STRING_PLEASE_VERIFY_EMAIL_ADDRESS_FIRST];
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                return;
            }
        }
        
        UITableViewCell *changeEmailNotificationsCell = [self.tableView cellForRowAtIndexPath:indexPath];
        changeEmailNotificationsCell.userInteractionEnabled = NO;
        [self addObserversForChangingNotifications];
    } else {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)addObserversForChangingNotifications
{
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeNotificationsSuccess) name:NOTIFICATION_KEY_CHANGE_NOTIFICATIONS_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeNotificationsError) name:NOTIFICATION_KEY_CHANGE_NOTIFICATIONS_ERROR object:nil];
}

- (void)removeObserversForChangingNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_NOTIFICATIONS_SUCCESS object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_NOTIFICATIONS_ERROR object:nil];
}

- (void)changeNotificationsSuccess
{
    [self removeObserversForChangingNotifications];
    
    SettingsNavigationController *navigationController = (SettingsNavigationController *)self.navigationController;
    [navigationController.busyView fadeIn];
    
    UITableViewCell *changeEmailNotificationsCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:preferencesEmailNotifications inSection:preferencesSectionNotificationsFooter]];
    UITableViewCell *changeSMSNotificationsCell = [self.tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:preferencesSMSNotifications inSection:preferencesSectionNotificationsFooter]];
    changeSMSNotificationsCell.userInteractionEnabled = YES;
    changeEmailNotificationsCell.userInteractionEnabled = YES;
}

- (void)changeNotificationsError
{
    [self removeObserversForChangingNotifications];
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:preferencesEmailNotifications inSection:preferencesSectionNotificationsFooter];
    
    UITableViewCell *changeEmailNotificationsCell = [self.tableView cellForRowAtIndexPath:indexPath];
    changeEmailNotificationsCell.userInteractionEnabled = YES;
    
    [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
}

- (void)toggleSMSNotifications
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:preferencesSMSNotifications inSection:preferencesSectionNotificationsFooter];
    
    if ([app checkInternetConnection]) {
        if ([self SMSNotificationsEnabled]) {
            [app.wallet disableSMSNotifications];
        } else {
            if ([app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_SMS_VERIFIED] boolValue] == YES) {
                [app.wallet enableSMSNotifications];
            } else {
                [self alertUserOfError:BC_STRING_PLEASE_VERIFY_MOBILE_NUMBER_FIRST];
                [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
                return;
            }
        }
        
        UITableViewCell *changeSMSNotificationsCell = [self.tableView cellForRowAtIndexPath:indexPath];
        changeSMSNotificationsCell.userInteractionEnabled = NO;
        [self addObserversForChangingNotifications];
    } else {
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

#pragma mark - Change Two Step

- (void)showTwoStep
{
    [self performSingleSegueWithIdentifier:SEGUE_IDENTIFIER_TWO_STEP sender:nil];
}

- (void)alertUserToChangeTwoStepVerification
{
    NSString *alertTitle;
    BOOL isTwoStepEnabled = YES;
    int twoStepType = [app.wallet getTwoStepType];
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
        
        if ([app.wallet getTwoStepType] == TWO_STEP_AUTH_TYPE_NONE) {
            self.isEnablingTwoStepSMS = YES;
            if ([app.wallet getSMSVerifiedStatus] == YES) {
                [self enableTwoStepForSMS];
            } else {
                [self mobileNumberClicked];
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
    return [app.wallet getEmail] ? YES : NO;
}

- (NSString *)getUserEmail
{
    return [app.wallet getEmail];
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
        
        NSString *newEmail = [[alertForChangingEmail textFields] firstObject].text;
        
        if ([[[newEmail lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""] isEqualToString:[[[self getUserEmail] lowercaseString] stringByReplacingOccurrencesOfString:@" " withString:@""]]) {
            [self alertUserOfError:BC_STRING_SETTINGS_NEW_EMAIL_MUST_BE_DIFFERENT];
            return;
        }
        
        if ([app.wallet emailNotificationsEnabled]) {
            [self alertUserAboutDisablingEmailNotifications:newEmail];
        } else {
            [self changeEmail:newEmail];
        }
        
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

- (void)alertUserAboutDisablingEmailNotifications:(NSString *)newEmail
{
    self.enteredEmailString = newEmail;
    
    UIAlertController *alertForChangingEmail = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_NEW_EMAIL_ADDRESS message:BC_STRING_SETTINGS_NEW_EMAIL_ADDRESS_WARNING_DISABLE_NOTIFICATIONS preferredStyle:UIAlertControllerStyleAlert];
    [alertForChangingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [alertForChangingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self disableNotificationsThenChangeEmail:newEmail];
    }]];
    
    if (self.alertTargetViewController) {
        [self.alertTargetViewController presentViewController:alertForChangingEmail animated:YES completion:nil];
    } else {
        [self presentViewController:alertForChangingEmail animated:YES completion:nil];
    }
}

- (void)disableNotificationsThenChangeEmail:(NSString *)newEmail
{
    SettingsNavigationController *navigationController = (SettingsNavigationController *)self.navigationController;
    [navigationController.busyView fadeIn];
    
    [app.wallet disableEmailNotifications];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeEmailAfterDisablingNotifications) name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
}

- (void)changeEmailAfterDisablingNotifications
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
    [self changeEmail:self.enteredEmailString];
}

- (void)alertUserToVerifyEmail
{
    UIAlertController *alertForVerifyingEmail = [UIAlertController alertControllerWithTitle:[[NSString alloc] initWithFormat:BC_STRING_VERIFICATION_EMAIL_SENT_TO_ARGUMENT, self.emailString] message:BC_STRING_PLEASE_CHECK_AND_CLICK_EMAIL_VERIFICATION_LINK preferredStyle:UIAlertControllerStyleAlert];
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
    [alertForVerifyingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_OPEN_MAIL_APP style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *mailURL = [NSURL URLWithString:PREFIX_MAIL_URI];
        if ([[UIApplication sharedApplication] canOpenURL:mailURL]) {
            [[UIApplication sharedApplication] openURL:mailURL];
        }
    }]];
    [alertForVerifyingEmail addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self getAccountInfo];
    }]];

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

#pragma mark - Wallet Recovery Phrase

- (void)showBackup
{
    if (!self.backupController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_BACKUP bundle: nil];
        self.backupController = [storyboard instantiateViewControllerWithIdentifier:NAVIGATION_CONTROLLER_NAME_BACKUP];
    }
    
    self.backupController.wallet = app.wallet;
    self.backupController.app = app;
    
    self.backupController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self presentViewController:self.backupController animated:YES completion:nil];
}

#pragma mark - Change Password

- (void)changePassword
{
    [self performSingleSegueWithIdentifier:SEGUE_IDENTIFIER_CHANGE_PASSWORD sender:nil];
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    __weak SettingsTableViewController *weakSelf = self;
    
    if (self.alertTargetViewController) {
        [self.alertTargetViewController dismissViewControllerAnimated:YES completion:^{
            if (textField.tag == textFieldTagVerifyMobileNumber) {
                [weakSelf verifyMobileNumber:textField.text];
                
            } else if (textField.tag == textFieldTagChangeMobileNumber) {
                [weakSelf changeMobileNumber:textField.text];
            }
        }];
        return YES;
    }
    
    [self dismissViewControllerAnimated:YES completion:^{
        if (textField.tag == textFieldTagVerifyMobileNumber) {
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

- (void)performSingleSegueWithIdentifier:(NSString *)identifier sender:(id)sender
{
    if ([[self navigationController] topViewController] == self) {
        [self performSegueWithIdentifier:identifier sender:sender];
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_CURRENCY]) {
        SettingsSelectorTableViewController *settingsSelectorTableViewController = segue.destinationViewController;
        settingsSelectorTableViewController.itemsDictionary = self.availableCurrenciesDictionary;
        settingsSelectorTableViewController.allCurrencySymbolsDictionary = self.allCurrencySymbolsDictionary;
    } else if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_BTC_UNIT]) {
        SettingsBitcoinUnitTableViewController *settingsBtcUnitTableViewController = segue.destinationViewController;
        settingsBtcUnitTableViewController.itemsDictionary = [app.wallet getBtcCurrencies];
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
                    [self walletIdentifierClicked];
                    return;
                }
            }
            return;
        }
        case preferencesSectionEmailFooter: {
            switch (indexPath.row) {
                case preferencesEmail: {
                    [self emailClicked];
                    return;
                }
            }
            return;
        }
        case preferencesSectionSMSFooter: {
            switch (indexPath.row) {
                case preferencesMobileNumber: {
                    [self mobileNumberClicked];
                    return;
                }
            }
            return;
        }
        case preferencesSectionNotificationsFooter: {
            return;
        }
        case preferencesSectionEnd: {
            switch (indexPath.row) {
                case displayLocalCurrency: {
                    [self performSingleSegueWithIdentifier:SEGUE_IDENTIFIER_CURRENCY sender:nil];
                    return;
                }
                case displayBtcUnit: {
                    [self performSingleSegueWithIdentifier:SEGUE_IDENTIFIER_BTC_UNIT sender:nil];
                    return;
                }
            }
        }
        case securitySection: {
            if (indexPath.row == securityTwoStep) {
                [self showTwoStep];
                return;
            } else if (indexPath.row == securityPasswordChange) {
                [self changePassword];
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
                case aboutUs: {
                    [self aboutUsClicked];
                    return;
                }
                case aboutTermsOfService: {
                    [self termsOfServiceClicked];
                    return;
                }
                case aboutPrivacyPolicy: {
                    [self showPrivacyPolicy];
                    return;
                }
            }
            return;
        }
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 8;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case walletInformationSection: return 1;
        case preferencesSectionEmailFooter: return 1;
        case preferencesSectionSMSFooter: return 1;
        case preferencesSectionNotificationsFooter: return 2;
        case preferencesSectionEnd: return 2;
        case securitySection: return [app.wallet didUpgradeToHd] ? 3 : 2;
        case PINSection: {
            if (PINTouchID > 0 && PINSwipeToReceive > 0) {
                return 3;
            } else if (PINTouchID > 0 || PINSwipeToReceive > 0) {
                return 2;
            } else {
                return 1;
            }
        }
        case aboutSection: return 3;
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
        case preferencesSectionSMSFooter: return BC_STRING_SETTINGS_SMS_FOOTER;
        case preferencesSectionNotificationsFooter: return BC_STRING_SETTINGS_NOTIFICATIONS_FOOTER;
        case PINSection: {return PINSwipeToReceive > 0 ? BC_STRING_SETTINGS_SWIPE_TO_RECEIVE_IN_FIVES_FOOTER : nil;}
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
                    
                    if ([self getUserEmail] != nil && [app.wallet getEmailVerifiedStatus] == YES) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_VERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_GREEN;
                    } else {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_UNVERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                    }
                    return [self adjustFontForCell:cell];
                }
            }
        }
        case preferencesSectionSMSFooter: {
            switch (indexPath.row) {
                case preferencesMobileNumber: {
                    cell.textLabel.text = BC_STRING_SETTINGS_MOBILE_NUMBER;
                    if ([app.wallet hasVerifiedMobileNumber]) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_VERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_GREEN;
                    } else {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_UNVERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                    }
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    return [self adjustFontForCell:cell];
                }
            }
        }
        case preferencesSectionNotificationsFooter: {
            switch (indexPath.row) {
                case preferencesEmailNotifications: {
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL_NOTIFICATIONS;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    UISwitch *switchForEmailNotifications = [[UISwitch alloc] init];
                    switchForEmailNotifications.on = [self emailNotificationsEnabled];
                    [switchForEmailNotifications addTarget:self action:@selector(toggleEmailNotifications) forControlEvents:UIControlEventTouchUpInside];
                    cell.accessoryView = switchForEmailNotifications;
                    return cell;
                }
                case preferencesSMSNotifications: {
                    cell.textLabel.text = BC_STRING_SETTINGS_SMS_NOTIFICATIONS;
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    UISwitch *switchForSMSNotifications = [[UISwitch alloc] init];
                    switchForSMSNotifications.on = [self SMSNotificationsEnabled];
                    [switchForSMSNotifications addTarget:self action:@selector(toggleSMSNotifications) forControlEvents:UIControlEventTouchUpInside];
                    cell.accessoryView = switchForSMSNotifications;
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
            }
        }
        case securitySection: {
            if (indexPath.row == securityTwoStep) {
                    cell.textLabel.text = BC_STRING_SETTINGS_SECURITY_TWO_STEP_VERIFICATION;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    int authType = [app.wallet getTwoStepType];
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
                    return [self adjustFontForCell:cell];
                }
            else if (indexPath.row == securityPasswordChange) {
                    cell.textLabel.text = BC_STRING_SETTINGS_SECURITY_CHANGE_PASSWORD;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    return [self adjustFontForCell:cell];
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
                    return [self adjustFontForCell:cell];
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
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.font = [SettingsTableViewController fontForCell];
                cell.textLabel.text = BC_STRING_SETTINGS_PIN_USE_TOUCH_ID_AS_PIN;
                UISwitch *switchForTouchID = [[UISwitch alloc] init];
                BOOL touchIDEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
                switchForTouchID.on = touchIDEnabled;
                [switchForTouchID addTarget:self action:@selector(switchTouchIDTapped) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = switchForTouchID;
                return cell;
            }
            if (indexPath.row == PINSwipeToReceive) {
                cell = [tableView dequeueReusableCellWithIdentifier:REUSE_IDENTIFIER_SWIPE_TO_RECEIVE];
                cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:REUSE_IDENTIFIER_SWIPE_TO_RECEIVE];
                cell.textLabel.adjustsFontSizeToFitWidth = YES;
                cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                cell.selectionStyle = UITableViewCellSelectionStyleNone;
                cell.textLabel.font = [SettingsTableViewController fontForCell];
                cell.textLabel.text = BC_STRING_SETTINGS_PIN_SWIPE_TO_RECEIVE;
                UISwitch *switchForSwipeToReceive = [[UISwitch alloc] init];
                BOOL swipeToReceiveEnabled = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_SWIPE_TO_RECEIVE_ENABLED];
                switchForSwipeToReceive.on = swipeToReceiveEnabled;
                [switchForSwipeToReceive addTarget:self action:@selector(switchSwipeToReceiveTapped) forControlEvents:UIControlEventTouchUpInside];
                cell.accessoryView = switchForSwipeToReceive;
                return cell;
            }
        }
        case aboutSection: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (indexPath.row) {
                case aboutUs: {
                    cell.textLabel.text = BC_STRING_SETTINGS_ABOUT_US;
                    return cell;
                }
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
    
    BOOL hasLoadedAccountInfoDictionary = app.wallet.hasLoadedAccountInfo ? YES : NO;
    
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
    [self emailClicked];
}

- (void)changeTwoStepTapped
{
    [self alertUserToChangeTwoStepVerification];
}

@end

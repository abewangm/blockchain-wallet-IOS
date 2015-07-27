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

const int alertViewTagErrorLoading = 6;

const int alertViewTagVerifyEmail = 5;
const int textFieldTagVerifyEmail = 55;

const int alertViewTagChangeEmail = 4;
const int textFieldTagChangeEmail = 44;

const int accountDetailsSection = 0;
const int displaySection = 1;
const int aboutSection = 2;

const int accountDetailsIdentifier = 0;
const int accountDetailsEmail = 1;
const int displayLocalCurrency = 0;
const int displayBtcUnit = 1;
const int aboutTermsOfService = 0;
const int aboutPrivacyPolicy = 1;

@interface SettingsTableViewController () <CurrencySelectorDelegate, BtcSelectorDelegate, UIAlertViewDelegate, UITextFieldDelegate>
@property (nonatomic, copy) NSDictionary *availableCurrenciesDictionary;
@property (nonatomic, copy) NSDictionary *accountInfoDictionary;
@property (nonatomic) UIAlertView *verifyEmailAlertView;
@property (nonatomic) UIAlertView *changeEmailAlertView;
@property (nonatomic, copy) NSString *enteredEmailString;
@property (nonatomic) id notificationObserver;
@end

@implementation SettingsTableViewController

// TODO: remove before merging
- (void)testForNilNSUserDefaults
{
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"email"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"btcUnit"];
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:@"currency"];
}

- (void)viewDidLoad
{
    [super viewDidLoad];

    [self getAccountInfo];
    
    self.availableCurrenciesDictionary = [app.wallet getAvailableCurrencies];
}

- (void)getAccountInfo;
{
    __weak SettingsTableViewController *weakSelf = self;
    
    self.notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil queue:nil usingBlock:^(NSNotification *note) {
        weakSelf.accountInfoDictionary = note.userInfo;
        [weakSelf.refreshControl endRefreshing];
    }];
    
    [app.wallet getAccountInfo];
}

- (void)setAccountInfoDictionary:(NSDictionary *)accountInfoDictionary
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.notificationObserver name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
    
    _accountInfoDictionary = accountInfoDictionary;
    
    NSString *emailString = _accountInfoDictionary[@"email"];
    
    if (emailString != nil) {
        [[NSUserDefaults standardUserDefaults] setValue:emailString forKey:@"email"];
    }
    
    [self.tableView reloadData];
}

- (void)changeLocalCurrencySuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_CHANGE_LOCAL_CURRENCY_SUCCESS object:nil];
    
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

- (void)alertViewForErrorLoadingSettings
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_SETTINGS_ERROR_LOADING_TITLE message:BC_STRING_SETTINGS_ERROR_LOADING_MESSAGE delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
    alertView.tag = alertViewTagErrorLoading;
    [alertView show];
}

- (void)alertViewToChangeEmail
{
    NSString *alertViewTitle = [self hasAddedEmail] ? BC_STRING_SETTINGS_CHANGE_EMAIL :BC_STRING_ADD_EMAIL;
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:alertViewTitle message:BC_STRING_PLEASE_PROVIDE_AN_EMAIL_ADDRESS delegate:self cancelButtonTitle:BC_STRING_CANCEL otherButtonTitles:BC_STRING_SETTINGS_VERIFY, nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.tag = textFieldTagChangeEmail;
    textField.delegate = self;
    textField.returnKeyType = UIReturnKeyDone;
    alertView.tag = alertViewTagChangeEmail;
    [alertView show];
    self.changeEmailAlertView = alertView;
}

- (void)alertViewToVerifyEmail
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_SETTINGS_VERIFY_EMAIL_ENTER_CODE message:[[NSString alloc] initWithFormat:BC_STRING_SETTINGS_SENT_TO_EMAIL, [[NSUserDefaults standardUserDefaults] objectForKey:@"email"]] delegate:self cancelButtonTitle:BC_STRING_CANCEL otherButtonTitles: BC_STRING_SETTINGS_VERIFY_EMAIL_RESEND, BC_STRING_SETTINGS_CHANGE_EMAIL, nil];
    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    UITextField *textField = [alertView textFieldAtIndex:0];
    textField.tag = textFieldTagVerifyEmail;
    textField.delegate = self;
    textField.returnKeyType = UIReturnKeyDone;
    alertView.tag = alertViewTagVerifyEmail;
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
    
    [app.wallet resendVerificationEmail:self.accountInfoDictionary[@"email"]];
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
    
    [[NSUserDefaults standardUserDefaults] setValue:self.enteredEmailString forKey:@"email"];
    
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
    switch (alertView.tag) {
        case alertViewTagChangeEmail: {switch (buttonIndex) {
            case 1: {
                [self changeEmail:[alertView textFieldAtIndex:0].text];
                return;
            }
        }
            return;
    }
        case alertViewTagVerifyEmail: {
            switch (buttonIndex) {
                case 0: {
                    [self getAccountInfo];
                    return;
                }
                case 1: {
                    [self resendVerificationEmail];
                    return;
                }
                case 2: {
                    [self alertViewToChangeEmail];
                    return;
                }
            }
            return;
        }
        case alertViewTagErrorLoading: {
            [self getAccountInfo];
            return;
        }
    }
}

#pragma mark - TextField Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.tag == textFieldTagVerifyEmail) {
        [self verifyEmailWithCode:textField.text];
        [self.verifyEmailAlertView dismissWithClickedButtonIndex:0 animated:YES];
    } else if (textField.tag == textFieldTagChangeEmail) {
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
                    ![self hasAddedEmail] || [self hasVerifiedEmail] ? [self alertViewToChangeEmail] : [self alertViewToVerifyEmail];
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
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case accountDetailsSection: return 2;
        case displaySection: return 2;
        case aboutSection: return 2;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case accountDetailsSection: return BC_STRING_SETTINGS_ACCOUNT_DETAILS;
        case displaySection: return BC_STRING_SETTINGS_DISPLAY_PREFERENCES;
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
                    cellWithSubtitle.textLabel.font = [SettingsTableViewController fontForCell];
                    cellWithSubtitle.textLabel.text = BC_STRING_SETTINGS_IDENTIFIER;
                    cellWithSubtitle.detailTextLabel.text = app.wallet.guid;
                    cellWithSubtitle.detailTextLabel.font = [SettingsTableViewController fontForCellSubtitle];
                    cellWithSubtitle.detailTextLabel.textColor = [UIColor grayColor];
                    cellWithSubtitle.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                    return cellWithSubtitle;
                }
                case accountDetailsEmail: {
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    
                    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"email"] && [self.accountInfoDictionary[@"email_verified"] boolValue] == YES) {
                        cell.detailTextLabel.text = [[NSUserDefaults standardUserDefaults] objectForKey:@"email"];
                    } else if ([self hasAddedEmail]) {
                        cell.detailTextLabel.text = BC_STRING_SETTINGS_EMAIL_UNVERIFIED;
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                    } else {
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                        cell.detailTextLabel.text = BC_STRING_ADD_EMAIL;
                    }
                    return cell;
                }
            }
        }
        case displaySection: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (indexPath.row) {
                case displayLocalCurrency: {
                    NSString *preferredCurrencySymbol = [[NSUserDefaults standardUserDefaults] valueForKey:@"currency"];
                    NSString *selectedCurrencyCode = preferredCurrencySymbol == nil ? [self getLocalSymbolFromLatestResponse].code : preferredCurrencySymbol;
                    NSString *currencyName = self.availableCurrenciesDictionary[selectedCurrencyCode];
                    cell.textLabel.text = BC_STRING_SETTINGS_LOCAL_CURRENCY;
                    cell.detailTextLabel.text = currencyName;
                    return cell;
                }
                case displayBtcUnit: {
                    NSString *preferredBtcSymbol = [[NSUserDefaults standardUserDefaults] valueForKey:@"btcUnit"];
                    NSString *selectedCurrencyCode = preferredBtcSymbol == nil ? [self getBtcSymbolFromLatestResponse].name : preferredBtcSymbol;
                    cell.textLabel.text = BC_STRING_SETTINGS_BTC;
                    cell.detailTextLabel.text = selectedCurrencyCode;
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

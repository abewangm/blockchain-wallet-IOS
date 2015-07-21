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
#import "AppDelegate.h"

#define TERMS_OF_SERVICE_URL @"https://blockchain.info/Resources/TermsofServicePolicy.pdf"
#define PRIVACY_POLICY_URL @"https://blockchain.info/Resources/PrivacyPolicy.pdf"

#define ALERTVIEW_TAG_VERIFY_EMAIL 5;
#define ALERTVIEW_TAG_ADD_EMAIL 4;

@interface SettingsTableViewController () <CurrencySelectorDelegate, UIAlertViewDelegate>
@property (nonatomic, copy) NSDictionary *availableCurrenciesDictionary;
@property (nonatomic, copy) NSDictionary *accountInfoDictionary;

@property (nonatomic, copy) NSString *emailString;
@end

@implementation SettingsTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil queue:nil usingBlock:^(NSNotification *note) {
        self.accountInfoDictionary = note.userInfo;
    }];
    [app.wallet getUserInfo];
    self.availableCurrenciesDictionary = [app.wallet getAvailableCurrencies];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
}

- (void)setAccountInfoDictionary:(NSDictionary *)accountInfoDictionary
{
    _accountInfoDictionary = accountInfoDictionary;
    
    if ([_accountInfoDictionary objectForKey:@"email"]) {
        self.emailString = [_accountInfoDictionary objectForKey:@"email"];
    } else {
        self.emailString = BC_STRING_PLEASE_PROVIDE_AN_EMAIL_ADDRESS;
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

- (CurrencySymbol *)getBtcSymbol
{
    return app.latestResponse.symbol_btc;
}

- (BOOL)hasAddedEmail
{
    return [self.accountInfoDictionary objectForKey:@"email"] ? YES : NO;
}

- (void)alertViewToAddEmail
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_ADD_EMAIL message:BC_STRING_PLEASE_PROVIDE_AN_EMAIL_ADDRESS delegate:self cancelButtonTitle:BC_STRING_CANCEL otherButtonTitles:BC_STRING_SETTINGS_VERIFY, nil];
    alertView.alertViewStyle = UIAlertViewStylePlainTextInput;
    alertView.tag = ALERTVIEW_TAG_ADD_EMAIL;
    [alertView show];
}

- (void)alertViewToVerifyEmail
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_SETTINGS_VERIFY_EMAIL message:BC_STRING_SETTINGS_VERIFY_EMAIL_ENTER_CODE delegate:self cancelButtonTitle:BC_STRING_CANCEL otherButtonTitles:BC_STRING_SETTINGS_VERIFY , BC_STRING_SETTINGS_VERIFY_EMAIL_RESEND, nil];
    alertView.alertViewStyle = UIAlertViewStyleSecureTextInput;
    alertView.tag = ALERTVIEW_TAG_VERIFY_EMAIL;
    [alertView show];
}

- (void)userAddedEmail:(NSString *)emailString
{
    [self alertViewToVerifyEmail];
}

#pragma mark AlertView Delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (alertView.tag) {
        case 4: {switch (buttonIndex) {
            case 1: {
                NSLog(@"add email");
                [self userAddedEmail:[alertView textFieldAtIndex:0].text];
                return;
            }
        }
            return;
    }
        case 5: {
            switch (buttonIndex) {
                case 1: {
                    NSLog(@"verify");
                    return;
                }
                case 2: {
                    NSLog(@"resend");
                    return;
                }
            }
            return;
        }
    }
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
    }
}

#pragma mark - Table view data source


- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 1: {
                    [self hasAddedEmail] ? [self alertViewToVerifyEmail] : [self alertViewToAddEmail];
                }
            }
            return;
        }
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    [self performSegueWithIdentifier:@"currency" sender:nil];
                    return;
                }
            }
            return;
        }
        case 3: {
            switch (indexPath.row) {
                case 0: {
                    [self performSegueWithIdentifier:@"about" sender:@"termsOfService"];
                    return;
                }
                case 1: {
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
        case 0: return 2;
        case 1: return 2;
        case 2: return 2;
        case 3: return 2;
        default: return 0;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return BC_STRING_SETTINGS_ACCOUNT_DETAILS;
        case 1: return BC_STRING_SETTINGS_DISPLAY_PREFERENCES;
        case 2: return BC_STRING_SETTINGS_NOTIFICATIONS;
        case 3: return BC_STRING_SETTINGS_ABOUT;
        default: return nil;
    }
}

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    switch (section) {
        case 0: return BC_STRING_SETTINGS_EMAIL_FOOTER;
        case 2: return BC_STRING_SETTINGS_NOTIFICATIONS_FOOTER;
        default: return nil;
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.font = [SettingsTableViewController fontForCell];
    cell.detailTextLabel.font = [SettingsTableViewController fontForCell];
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    UITableViewCell *cellWithSubtitle = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:nil];
                    cellWithSubtitle.textLabel.font = [SettingsTableViewController fontForCell];
                    cellWithSubtitle.textLabel.text = BC_STRING_SETTINGS_IDENTIFIER;
                    cellWithSubtitle.detailTextLabel.text = app.wallet.guid;
                    cellWithSubtitle.detailTextLabel.font = [SettingsTableViewController fontForCellSubtitle];
                    cellWithSubtitle.detailTextLabel.textColor = [UIColor grayColor];
                    cellWithSubtitle.detailTextLabel.adjustsFontSizeToFitWidth = YES;
                    return cellWithSubtitle;
                }
                case 1: {
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL;
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    if ([self hasAddedEmail]) {
                        cell.detailTextLabel.text = self.emailString;
                    } else {
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                        cell.detailTextLabel.text = BC_STRING_ADD_EMAIL;
                    }
                    return cell;
                }
            }
        }
        case 1: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (indexPath.row) {
                case 0: {
                    NSString *preferredCurrencySymbol = [[NSUserDefaults standardUserDefaults] valueForKey:@"currency"];
                    NSString *selectedCurrencyCode = preferredCurrencySymbol == nil ? [self getLocalSymbolFromLatestResponse].code : preferredCurrencySymbol;
                    NSString *currencyName = self.availableCurrenciesDictionary[selectedCurrencyCode];
                    cell.textLabel.text = BC_STRING_SETTINGS_LOCAL_CURRENCY;
                    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@ (%@)", currencyName, @""];
                    return cell;
                }
                case 1: {
                    cell.textLabel.text = BC_STRING_SETTINGS_BTC;
                    cell.detailTextLabel.text = [self getBtcSymbol].name;
                    return cell;
                }
            }
        }
        case 2: {
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL;
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchView;
                    return cell;
                }
                case 1: {
                    cell.textLabel.text = BC_STRING_SETTINGS_NOTIFICATIONS_SMS;
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchView;
                    return cell;
                }
            }
        }
        case 3: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = BC_STRING_SETTINGS_TERMS_OF_SERVICE;
                    return cell;
                }
                case 1: {
                    cell.textLabel.text = BC_STRING_SETTINGS_PRIVACY_POLICY;
                    return cell;
                }
            }
        }        default: return nil;
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 2: return nil;
        default: return indexPath;
    }
}

@end

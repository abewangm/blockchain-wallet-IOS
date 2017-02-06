//
//  DebugTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/29/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "DebugTableViewController.h"
#import "Blockchain-Swift.h"
#import "RootService.h"

const int rowWalletJSON = 0;
const int rowServerURL = 1;
const int rowWebsocketURL = 2;
const int rowMerchantURL = 3;
const int rowAPIURL = 4;
const int rowSurgeToggle = 5;
const int rowDontShowAgain = 6;
const int rowAppStoreReviewPromptTimer = 7;
const int rowCertificatePinning = 8;
const int rowTestnet = 9;
const int rowSecurityReminderTimer = 10;
const int rowZeroTickerValue = 11;

@interface DebugTableViewController ()
@property (nonatomic) NSDictionary *filteredWalletJSON;
@end

@implementation DebugTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:BC_STRING_DONE style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    self.navigationController.navigationBar.barTintColor = COLOR_BLOCKCHAIN_BLUE;
    NSString *presenter;
    if (self.presenter == DEBUG_PRESENTER_SETTINGS_ABOUT) {
        presenter = BC_STRING_SETTINGS_ABOUT;
    } else if (self.presenter == DEBUG_PRESENTER_PIN_VERIFY) {
        presenter = BC_STRING_SETTINGS_VERIFY;
    } else if (self.presenter == DEBUG_PRESENTER_WELCOME_VIEW)  {
        presenter = DEBUG_STRING_WELCOME;
    }
    self.navigationItem.title = [NSString stringWithFormat:@"%@ %@ %@", DEBUG_STRING_DEBUG, DEBUG_STRING_FROM_LOWERCASE, presenter];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    self.filteredWalletJSON = [app.wallet filteredWalletJSON];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)alertToChangeURLName:(NSString *)name userDefaultKey:(NSString *)key currentURL:(NSString *)currentURL
{
    UIAlertController *changeURLAlert = [UIAlertController alertControllerWithTitle:name message:nil preferredStyle:UIAlertControllerStyleAlert];
    [changeURLAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.text = currentURL;
        secureTextField.returnKeyType = UIReturnKeyDone;
    }];
    [changeURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)[[changeURLAlert textFields] firstObject];
        [[NSUserDefaults standardUserDefaults] setObject:secureTextField.text forKey:key];
        [self.tableView reloadData];
    }]];
    [changeURLAlert addAction:[UIAlertAction actionWithTitle:DEBUG_STRING_RESET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        [self.tableView reloadData];
    }]];
    [changeURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:changeURLAlert animated:YES completion:nil];
}

- (void)toggleSurge
{
    BOOL surgeOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_SIMULATE_SURGE];
    [[NSUserDefaults standardUserDefaults] setBool:!surgeOn forKey:USER_DEFAULTS_KEY_DEBUG_SIMULATE_SURGE];
}

- (void)togglePinning
{
    BOOL pinningOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_ENABLE_CERTIFICATE_PINNING];
    [[NSUserDefaults standardUserDefaults] setBool:!pinningOn forKey:USER_DEFAULTS_KEY_DEBUG_ENABLE_CERTIFICATE_PINNING];
}

- (void)toggleTestnet
{
    BOOL testnetOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_ENABLE_TESTNET];
    [[NSUserDefaults standardUserDefaults] setBool:!testnetOn forKey:USER_DEFAULTS_KEY_DEBUG_ENABLE_TESTNET];
    
    if (!testnetOn) {
        [[NSUserDefaults standardUserDefaults] setObject:TESTNET_WALLET_SERVER forKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL];
        [[NSUserDefaults standardUserDefaults] setObject:TESTNET_WEBSOCKET_SERVER forKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL];
        [[NSUserDefaults standardUserDefaults] setObject:TESTNET_API_URL forKey:USER_DEFAULTS_KEY_DEBUG_API_URL];
    } else {
        [[NSUserDefaults standardUserDefaults] setObject:DEFAULT_WALLET_SERVER forKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL];
        [[NSUserDefaults standardUserDefaults] setObject:DEFAULT_WEBSOCKET_SERVER forKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL];
        [[NSUserDefaults standardUserDefaults] setObject:DEFAULT_API_URL forKey:USER_DEFAULTS_KEY_DEBUG_API_URL];
    }
    
    [self.tableView reloadData];
}

- (void)toggleZeroTicker
{
    BOOL zeroTickerOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_SIMULATE_ZERO_TICKER];
    [[NSUserDefaults standardUserDefaults] setBool:!zeroTickerOn forKey:USER_DEFAULTS_KEY_DEBUG_SIMULATE_ZERO_TICKER];
}

- (void)showFilteredWalletJSON
{
    UIViewController *viewController = [[UIViewController alloc] init];
    UITextView *walletJSONTextView = [[UITextView alloc] initWithFrame:viewController.view.frame];
    walletJSONTextView.text = [NSString stringWithFormat:@"%@", self.filteredWalletJSON];
    walletJSONTextView.editable = NO;
    [viewController.view addSubview:walletJSONTextView];
    [self.navigationController pushViewController:viewController animated:YES];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 12;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;

    switch (indexPath.row) {
        case rowWalletJSON: {
            cell.textLabel.text = DEBUG_STRING_WALLET_JSON;
            cell.detailTextLabel.text = self.filteredWalletJSON == nil ? DEBUG_STRING_PLEASE_LOGIN : nil;
            cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
            cell.accessoryType = self.filteredWalletJSON == nil ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case rowServerURL: {
            cell.textLabel.text = DEBUG_STRING_SERVER_URL;
            cell.detailTextLabel.text =  URL_SERVER;
            break;
        }
        case rowWebsocketURL: {
            cell.textLabel.text = DEBUG_STRING_WEBSOCKET_URL;
            cell.detailTextLabel.text = URL_WEBSOCKET;
            break;
        }
        case rowMerchantURL: {
            cell.textLabel.text = DEBUG_STRING_MERCHANT_URL;
            cell.detailTextLabel.text = URL_MERCHANT;
            break;
        }
        case rowAPIURL: {
            cell.textLabel.text = DEBUG_STRING_API_URL;
            cell.detailTextLabel.text = URL_API;
            break;
        }
        case rowSurgeToggle: {
            cell.textLabel.text = DEBUG_STRING_SIMULATE_SURGE;
            UISwitch *surgeToggle = [[UISwitch alloc] init];
            BOOL surgeOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_SIMULATE_SURGE];
            surgeToggle.on = surgeOn;
            [surgeToggle addTarget:self action:@selector(toggleSurge) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = surgeToggle;
            break;
        }
        case rowDontShowAgain: {
            cell.textLabel.text = DEBUG_STRING_RESET_DONT_SHOW_AGAIN_PROMPT;
            break;
        }
        case rowAppStoreReviewPromptTimer: {
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.text = DEBUG_STRING_APP_STORE_REVIEW_PROMPT_TIMER;
            break;
        }
        case rowCertificatePinning: {
            cell.textLabel.text = DEBUG_STRING_CERTIFICATE_PINNING;
            UISwitch *pinningToggle = [[UISwitch alloc] init];
            BOOL pinningOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_ENABLE_CERTIFICATE_PINNING];
            pinningToggle.on = pinningOn;
            [pinningToggle addTarget:self action:@selector(togglePinning) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = pinningToggle;
            break;
        }
        case rowTestnet: {
            cell.textLabel.text = DEBUG_STRING_TESTNET;
            UISwitch *testnetToggle = [[UISwitch alloc] init];
            BOOL testnetOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_ENABLE_TESTNET];
            testnetToggle.on = testnetOn;
            [testnetToggle addTarget:self action:@selector(toggleTestnet) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = testnetToggle;
            break;
        }
        case rowSecurityReminderTimer: {
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.text = DEBUG_STRING_SECURITY_REMINDER_PROMPT_TIMER;
            break;
        }
        case rowZeroTickerValue: {
            cell.textLabel.adjustsFontSizeToFitWidth = YES;
            cell.textLabel.text = DEBUG_STRING_ZERO_VALUE_TICKER;
            UISwitch *zeroTickerToggle = [[UISwitch alloc] init];
            BOOL zeroTickerOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_SIMULATE_ZERO_TICKER];
            zeroTickerToggle.on = zeroTickerOn;
            [zeroTickerToggle addTarget:self action:@selector(toggleZeroTicker) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = zeroTickerToggle;
        }
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case rowWalletJSON: {
            if (self.filteredWalletJSON) {
                [self showFilteredWalletJSON];
            }
            break;
        }
        case rowServerURL:
            [self alertToChangeURLName:DEBUG_STRING_SERVER_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL currentURL:URL_SERVER];
            break;
        case rowWebsocketURL:
            [self alertToChangeURLName:DEBUG_STRING_WEBSOCKET_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL currentURL:URL_WEBSOCKET];
            break;
        case rowMerchantURL:
            [self alertToChangeURLName:DEBUG_STRING_MERCHANT_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_MERCHANT_URL currentURL:URL_MERCHANT];
            break;
        case rowAPIURL:
            [self alertToChangeURLName:DEBUG_STRING_API_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_API_URL currentURL:URL_API];
            break;
        case rowDontShowAgain: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:DEBUG_STRING_DEBUG message:DEBUG_STRING_RESET_DONT_SHOW_AGAIN_PROMPT_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:DEBUG_STRING_RESET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:USER_DEFAULTS_KEY_HIDE_TRANSFER_ALL_FUNDS_ALERT];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:USER_DEFAULTS_KEY_HIDE_APP_REVIEW_PROMPT];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:USER_DEFAULTS_KEY_HIDE_WATCH_ONLY_RECEIVE_WARNING];
                [[NSUserDefaults standardUserDefaults] setBool:NO forKey:USER_DEFAULTS_KEY_HAS_SEEN_SURVEY_PROMPT];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
        case rowAppStoreReviewPromptTimer: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:DEBUG_STRING_DEBUG message:DEBUG_STRING_APP_STORE_REVIEW_PROMPT_TIMER preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[[[alert textFields] firstObject].text intValue]] forKey:USER_DEFAULTS_KEY_DEBUG_APP_REVIEW_PROMPT_CUSTOM_TIMER];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:DEBUG_STRING_RESET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:TIME_INTERVAL_APP_STORE_REVIEW_PROMPT] forKey:USER_DEFAULTS_KEY_DEBUG_APP_REVIEW_PROMPT_CUSTOM_TIMER];
            }]];
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.keyboardType = UIKeyboardTypeNumberPad;
                
                id customTimeValue = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_APP_REVIEW_PROMPT_CUSTOM_TIMER];
                
                textField.text = [NSString stringWithFormat:@"%i", customTimeValue ? [customTimeValue intValue] : TIME_INTERVAL_APP_STORE_REVIEW_PROMPT];
            }];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
        case rowSecurityReminderTimer: {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:DEBUG_STRING_DEBUG message:DEBUG_STRING_SECURITY_REMINDER_PROMPT_TIMER preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:[[[alert textFields] firstObject].text intValue]] forKey:USER_DEFAULTS_KEY_DEBUG_SECURITY_REMINDER_CUSTOM_TIMER];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
            [alert addAction:[UIAlertAction actionWithTitle:DEBUG_STRING_RESET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInt:TIME_INTERVAL_SECURITY_REMINDER_PROMPT] forKey:USER_DEFAULTS_KEY_DEBUG_SECURITY_REMINDER_CUSTOM_TIMER];
            }]];
            [alert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
                textField.keyboardType = UIKeyboardTypeNumberPad;
                
                id customTimeValue = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_SECURITY_REMINDER_CUSTOM_TIMER];
                
                textField.text = [NSString stringWithFormat:@"%i", customTimeValue ? [customTimeValue intValue] : TIME_INTERVAL_SECURITY_REMINDER_PROMPT];
            }];
            [self presentViewController:alert animated:YES completion:nil];
            break;
        }
        default:
            break;
    }
}


@end

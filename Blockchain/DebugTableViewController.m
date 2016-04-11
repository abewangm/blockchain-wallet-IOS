//
//  DebugTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/29/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//

#import "DebugTableViewController.h"
#import "Blockchain-Swift.h"
#import "AppDelegate.h"

const int rowWalletJSON = 0;
const int rowServerURL = 1;
const int rowWebsocketURL = 2;
const int rowMerchantURL = 3;
const int rowAPIURL = 4;
const int surgeToggle = 5;

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
        presenter = BC_STRING_WELCOME;
    }
    self.navigationItem.title = [NSString stringWithFormat:@"%@ %@ %@", BC_STRING_DEBUG, BC_STRING_FROM_LOWERCASE, presenter];
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
    [changeURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_RESET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        [self.tableView reloadData];
    }]];
    [changeURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:changeURLAlert animated:YES completion:nil];
}

- (void)toggleSurge
{
    BOOL surgeOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_SIMULATE_SURGE];
    [[NSUserDefaults standardUserDefaults] setBool:!surgeOn forKey:USER_DEFAULTS_KEY_SIMULATE_SURGE];
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
    return 6;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;

    switch (indexPath.row) {
        case rowWalletJSON: {
            cell.textLabel.text = BC_STRING_WALLET_JSON;
            cell.detailTextLabel.text = self.filteredWalletJSON == nil ? BC_STRING_PLEASE_LOGIN : nil;
            cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
            cell.accessoryType = self.filteredWalletJSON == nil ? UITableViewCellAccessoryNone : UITableViewCellAccessoryDisclosureIndicator;
            break;
        }
        case rowServerURL: {
            cell.textLabel.text = BC_STRING_SERVER_URL;
            cell.detailTextLabel.text =  [app serverURL];
            break;
        }
        case rowWebsocketURL: {
            cell.textLabel.text = BC_STRING_WEBSOCKET_URL;
            cell.detailTextLabel.text = [app webSocketURL];
            break;
        }
        case rowMerchantURL: {
            cell.textLabel.text = BC_STRING_MERCHANT_URL;
            cell.detailTextLabel.text = [app merchantURL];
            break;
        }
        case rowAPIURL: {
            cell.textLabel.text = BC_STRING_API_URL;
            cell.detailTextLabel.text = [app apiURL];
            break;
        }
        case surgeToggle: {
            cell.textLabel.text = BC_STRING_SIMULATE_SURGE;
            UISwitch *surgeToggle = [[UISwitch alloc] init];
            BOOL surgeOn = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_SIMULATE_SURGE];
            surgeToggle.on = surgeOn;
            [surgeToggle addTarget:self action:@selector(toggleSurge) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = surgeToggle;
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
            [self alertToChangeURLName:BC_STRING_SERVER_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL currentURL:[app serverURL]];
            break;
        case rowWebsocketURL:
            [self alertToChangeURLName:BC_STRING_WEBSOCKET_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL currentURL:[app webSocketURL]];
            break;
        case rowMerchantURL:
            [self alertToChangeURLName:BC_STRING_MERCHANT_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_MERCHANT_URL currentURL:[app merchantURL]];
            break;
        case rowAPIURL:
            [self alertToChangeURLName:BC_STRING_API_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_API_URL currentURL:[app apiURL]];
        default:
            break;
    }
}


@end

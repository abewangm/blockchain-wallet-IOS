//
//  SettingsTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/13/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "SettingsSelectorTableViewController.h"
#import "AppDelegate.h"

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

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
    // TODO: This needs to observe the change as well
    return app.latestResponse.symbol_local;
}

- (CurrencySymbol *)getBtcSymbol
{
    return [app.wallet getBTCSymbol];
}

- (NSDictionary *)getAvailableCurrencies
{
    return [app.wallet getAvailableCurrencies];
}

#pragma mark - Segue

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    
    switch (indexPath.section) {
        case 1: {
            switch (indexPath.row) {
                case 0: {
                    [self performSegueWithIdentifier:@"currency" sender:nil];
                }
            }
        }
    }
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"currency"]) {
        SettingsSelectorTableViewController *settingsSelectorTableViewController = segue.destinationViewController;
        settingsSelectorTableViewController.itemsDictionary = [self getAvailableCurrencies];
    }
}

#pragma mark - Table view data source

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
                    if (app.showEmailWarning) {
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                        cell.detailTextLabel.text = BC_STRING_ADD_EMAIL;
                    } else {
                        cell.detailTextLabel.text = @"SETTINGSJS:useremail";
                    }
                    return cell;
                }
            }
        }
        case 1: {
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
            switch (indexPath.row) {
                case 0: {
                    cell.textLabel.text = BC_STRING_SETTINGS_LOCAL_CURRENCY;
                    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@ (%@)", [self getLocalSymbolFromLatestResponse].name, @""];
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

@end

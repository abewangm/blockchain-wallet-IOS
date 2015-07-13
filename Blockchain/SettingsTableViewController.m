//
//  SettingsTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/13/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "AppDelegate.h"

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 3;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    switch (section) {
        case 0: return 2;
        case 1: return 2;
        case 2: return 2;
        default: return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return [SettingsTableViewController headerView:tableView withText:BC_STRING_SETTINGS_ACCOUNT_DETAILS];
        case 1: return [SettingsTableViewController headerView:tableView withText:BC_STRING_SETTINGS_DISPLAY_PREFERENCES];
        case 2: return [SettingsTableViewController headerView:tableView withText:BC_STRING_SETTINGS_NOTIFICATIONS];
        default: return nil;
    }
}

+ (UIView *)headerView:(UITableView *)tableView withText:(NSString *)text
{
    // duplicate code for now but may add different descriptions

    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 35)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 2.5, tableView.frame.size.width, 18)];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Helvetica Neue" size:15];
    label.text = text;
    [view addSubview:label];
    [view setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    return view;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                    
                    cell.textLabel.text = BC_STRING_SETTINGS_IDENTIFIER;
                    cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.text = app.wallet.guid;
                    return cell;
                }
                case 1: {
                    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                    
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL;
                    cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
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
            switch (indexPath.row) {
                case 0: {
                    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                    
                    cell.textLabel.text = BC_STRING_SETTINGS_LOCAL_CURRENCY;
                    cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.text = @"SETTINGSJS:localcurrency";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    return cell;
                }
                case 1: {
                    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                    
                    cell.textLabel.text = BC_STRING_SETTINGS_BTC;
                    cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.text = @"SETTINGSJS:bitcoinunit";
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;;
                    return cell;
                }
            }
        }
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                    
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL;
                    cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchView;
                    return cell;
                }
                case 1: {
                    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
                    
                    cell.textLabel.text = BC_STRING_SETTINGS_NOTIFICATIONS_SMS;
                    cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];

                    UISwitch *switchView = [[UISwitch alloc] initWithFrame:CGRectZero];
                    cell.accessoryView = switchView;
                    return cell;
                }
            }
        }
        default: return nil;
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    [self performSegueWithIdentifier:@"walletID" sender:nil];
}

@end

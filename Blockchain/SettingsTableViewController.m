//
//  SettingsTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/13/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsTableViewController.h"
#import "SettingsViewController.h"
#import "AppDelegate.h"

@interface SettingsTableViewController ()

@end

@implementation SettingsTableViewController

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    // Return the number of sections.
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    switch (section) {
        case 0: return 2;
        default: return 0;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    switch (section) {
        case 0: return [SettingsTableViewController headerViewForAccountDetails:tableView];
        default: return nil;
    }
}

+ (UIView *)headerViewForAccountDetails:(UITableView *)tableView
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.frame.size.width, 25)];
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(10, 2.5, tableView.frame.size.width, 18)];
    label.textColor = [UIColor whiteColor];
    label.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
    label.text = BC_STRING_SETTINGS_ACCOUNT_DETAILS;
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
                    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"YourIdentifier"];
                    
                    cell.textLabel.text = BC_STRING_SETTINGS_IDENTIFIER;
                    cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.text = app.wallet.guid;
                    return cell;
                }
                case 1: {
                    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"YourIdentifier"];
                    
                    cell.textLabel.text = BC_STRING_SETTINGS_EMAIL;
                    cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:12];
                    if (app.showEmailWarning) {
                        cell.detailTextLabel.textColor = COLOR_BUTTON_RED;
                        cell.detailTextLabel.text = BC_STRING_ADD_EMAIL;
                    } else {
                        cell.detailTextLabel.text = @"useremail";
                    }
                    return cell;
                }
            }   case 2: {
                return nil;
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

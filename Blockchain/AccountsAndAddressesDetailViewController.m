//
//  AccountsAndAddressesDetailViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 1/14/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import "AccountsAndAddressesNavigationController.h"
#import "AccountsAndAddressesDetailViewController.h"
#import "AppDelegate.h"

@interface AccountsAndAddressesDetailViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) UITableView *tableView;
@end

const int numberOfSectionsAccountUnarchived = 2;
const int numberOfSectionsAddressUnarchived = 1; // 2 if watch only
const int numberOfSectionsArchived = 1;

const int numberOfRowsAccountUnarchived = 3;
const int numberOfRowsAddressUnarchived = 3;

const int rowAccountUnarchivedName = 0;
const int rowAccountUnarchivedMakeDefault = 1;
const int rowAccountUnarchivedExtendedPublicKey = 2;

const int rowAddressUnarchivedName = 0;
const int rowAddressUnarchivedDetail = 1;
const int rowAddressUnarchivedArchive = 2;
const int rowAddressUnarchivedScanPrivateKey = 2;

const int sectionArchived = 1;
const int numberOfRowsArchived = 1;

@implementation AccountsAndAddressesDetailViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    
    if (self.account < 0 && !self.address) {
        DLog(@"Error: no account or address set!");
    }
    
    AccountsAndAddressesNavigationController *navigationController = (AccountsAndAddressesNavigationController *)self.navigationController;
    navigationController.headerLabel.text = self.address ? [app.wallet labelForLegacyAddress:self.address] : [app.wallet getLabelForAccount:self.account];
}

- (BOOL)isArchived
{
    return [app.wallet isAddressArchived:self.address] || [app.wallet isAccountArchived:self.account];
}

- (void)labelAddressClicked
{
    
}

- (void)labelAccountClicked
{
    
}

#pragma mark Table View Delegate

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    if (section == 0) {
        if ([self isArchived]) {
            return BC_STRING_ARCHIVED_FOOTER_TITLE;
        } else {
            if (self.address) {
                return [app.wallet isWatchOnlyLegacyAddress:self.address] ? BC_STRING_WATCH_ONLY_FOOTER_TITLE : BC_STRING_ARCHIVE_FOOTER_TITLE;
            } else {
                return BC_STRING_EXTENDED_PUBLIC_KEY_FOOTER_TITLE;
            }
        }
    } else if (section == 1) {
        return BC_STRING_ARCHIVE_FOOTER_TITLE;
    }
    
    return nil;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    if ([self isArchived]) {
        return numberOfSectionsArchived;
    }
    
    if (self.address) {
        return [app.wallet isWatchOnlyLegacyAddress:self.address] ? numberOfSectionsAddressUnarchived + 1 : numberOfSectionsAddressUnarchived;
    } else {
        return numberOfSectionsAccountUnarchived;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0) {
        
        if ([self isArchived]) {
            return 1;
        } else {
            return self.address ? numberOfRowsAddressUnarchived : numberOfRowsAccountUnarchived;
        }
    }
    
    if (section == sectionArchived) {
        return numberOfRowsArchived;
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0: {
            if (self.address) {
                [self labelAddressClicked];
            } else {
                [self labelAccountClicked];
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:15];
    cell.detailTextLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:15];
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    if ([self isArchived]) {
                        cell.textLabel.text = BC_STRING_ARCHIVED;
                        UISwitch *archiveSwitch = [[UISwitch alloc] init];
                        cell.accessoryView = archiveSwitch;
                    } else {
                        cell.textLabel.text = self.address? BC_STRING_LABEL : BC_STRING_NAME;
                        cell.detailTextLabel.text = self.address ? [app.wallet labelForLegacyAddress:self.address] : [app.wallet getLabelForAccount:self.account];
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    return cell;
                }
                case 1: {
                    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    if (self.address) {
                        cell.textLabel.text = BC_STRING_ADDRESS;
                        cell.detailTextLabel.text = self.address;
                    } else {
                        cell.textLabel.text = BC_STRING_MAKE_DEFAULT;
                    }
                    return cell;
                }
                case 2: {
                    if (self.address) {
                        if ([app.wallet isWatchOnlyLegacyAddress:self.address]) {
                            cell.textLabel.text = BC_STRING_SCAN_PRIVATE_KEY;
                            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                        } else {
                            cell.textLabel.text = BC_STRING_ARCHIVED;
                            UISwitch *archiveSwitch = [[UISwitch alloc] init];
                            cell.accessoryView = archiveSwitch;
                        }
                    } else {
                        cell.textLabel.text = BC_STRING_EXTENDED_PUBLIC_KEY;
                        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
                    }
                    return cell;
                }
                default: return nil;
            }
        }
        case sectionArchived: {
            cell.textLabel.text = BC_STRING_ARCHIVED;
            UISwitch *archiveSwitch = [[UISwitch alloc] init];
            cell.accessoryView = archiveSwitch;
            return cell;
        }
        default:
            return nil;
    }
}

@end

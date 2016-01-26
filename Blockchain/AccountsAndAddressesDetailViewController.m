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
    navigationController.headerLabel.text = self.address ? [app.wallet labelForLegacyAddress:self.address] : [app.wallet getLabelForAccount:self.account activeOnly:NO];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NOTIFICATION_KEY_RELOAD_ACCOUNTS_AND_ADDRESSES object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reload
{
    [self.tableView reloadData];
}

- (BOOL)isArchived
{
    return [app.wallet isAddressArchived:self.address] || [app.wallet isAccountArchived:self.account];
}

- (void)showBusyView
{
    AccountsAndAddressesNavigationController *navigationController = (AccountsAndAddressesNavigationController *)self.navigationController;
    [navigationController.busyView fadeIn];
}

- (void)labelAddressClicked
{
    
}

- (void)labelAccountClicked
{
    
}

- (void)showAddress:(NSString *)address
{
    
}

- (void)showAccountXPub:(int)account
{
    
}

- (void)setDefaultAccount:(int)account
{
    [self showBusyView];
    [app.wallet setDefaultAccount:account];
}

- (void)toggleArchive
{
    [self showBusyView];
    if (self.address) {
        [app.wallet toggleArchiveLegacyAddress:self.address];
    } else {
        [app.wallet toggleArchiveAccount:self.account];
    }
}

- (void)scanPrivateKey
{

}

- (void)alertToConfirmSetDefaultAccount:(int)account
{
    UIAlertController *alertToSetDefaultAccount = [UIAlertController alertControllerWithTitle:BC_STRING_SET_DEFAULT_ACCOUNT message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertToSetDefaultAccount addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self setDefaultAccount:account];
    }]];
    [alertToSetDefaultAccount addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertToSetDefaultAccount animated:YES completion:nil];
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
            return numberOfRowsArchived;
        } else {
            if (self.address) {
                return numberOfRowsAddressUnarchived;
            } else {
                return [app.wallet getDefaultAccountIndex] == self.account ? numberOfRowsAccountUnarchived - 1 : numberOfRowsAccountUnarchived;
            }
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
            if ([self isArchived]) {
                switch (indexPath.row) {
                    case 0: {
                        return;
                    }
                }
            } else {
                switch (indexPath.row) {
                    case 0: {
                        if (self.address) {
                            [self labelAddressClicked];
                        } else {
                            [self labelAccountClicked];
                        }
                        return;
                    }
                    case 1: {
                        if (self.address) {
                            [self showAddress:self.address];
                        } else {
                            if ([app.wallet getDefaultAccountIndex] != self.account) {
                                [self alertToConfirmSetDefaultAccount:self.account];
                            } else {
                                [self showAccountXPub:self.account];
                            }
                        }
                        return;
                    }
                    case 2: {
                        if (self.address) {
                            if ([app.wallet isWatchOnlyLegacyAddress:self.address]) {
                                [self scanPrivateKey];
                            }
                        } else {
                            [self showAccountXPub:self.account];
                        }
                        return;
                    }
                }
            }
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.font = [UIFont fontWithName:FONT_HELVETICA_NUEUE size:15];
    cell.detailTextLabel.font = [UIFont fontWithName:FONT_HELVETICA_NUEUE size:15];
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    
    switch (indexPath.section) {
        case 0: {
            switch (indexPath.row) {
                case 0: {
                    if ([self isArchived]) {
                        cell.textLabel.text = BC_STRING_ARCHIVED;
                        UISwitch *archiveSwitch = [[UISwitch alloc] init];
                        archiveSwitch.on = [self isArchived];
                        [archiveSwitch addTarget:self action:@selector(toggleArchive) forControlEvents:UIControlEventTouchUpInside];
                        cell.accessoryView = archiveSwitch;
                    } else {
                        cell.textLabel.text = self.address? BC_STRING_LABEL : BC_STRING_NAME;
                        cell.detailTextLabel.text = self.address ? [app.wallet labelForLegacyAddress:self.address] : [app.wallet getLabelForAccount:self.account activeOnly:NO];
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
                        if ([app.wallet getDefaultAccountIndex] != self.account) {
                            cell.textLabel.text = BC_STRING_MAKE_DEFAULT;
                        } else {
                            cell.textLabel.text = BC_STRING_EXTENDED_PUBLIC_KEY;
                        }
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
                            archiveSwitch.on = [self isArchived];
                            [archiveSwitch addTarget:self action:@selector(toggleArchive) forControlEvents:UIControlEventTouchUpInside];
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
            archiveSwitch.on = [self isArchived];
            [archiveSwitch addTarget:self action:@selector(toggleArchive) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = archiveSwitch;
            return cell;
        }
        default:
            return nil;
    }
}

@end

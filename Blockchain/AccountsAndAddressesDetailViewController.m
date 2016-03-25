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
#import "BCEditAccountView.h"
#import "BCEditAddressView.h"
#import "BCQRCodeView.h"
#import "PrivateKeyReader.h"
#import "UIViewController+AutoDismiss.h"
#import "SendViewController.h"

const int numberOfSectionsAccountUnarchived = 2;
const int numberOfSectionsAddressUnarchived = 1; // 2 if watch only
const int numberOfSectionsArchived = 1;

const int numberOfRowsAccountUnarchived = 3;
const int numberOfRowsAddressUnarchived = 3;

const int numberOfRowsArchived = 1;

const int numberOfRowsTransfer = 1;

typedef enum {
    DetailTypeShowExtendedPublicKey = 100,
    DetailTypeShowAddress = 200,
    DetailTypeEditAccountLabel = 300,
    DetailTypeEditAddressLabel = 400,
    DetailTypeScanPrivateKey = 500,
}DetailType;

@interface AccountsAndAddressesDetailViewController () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) UITableView *tableView;
@end

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
    
    [self resetHeader];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NOTIFICATION_KEY_RELOAD_ACCOUNTS_AND_ADDRESSES object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    [self resetHeader];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)resetHeader
{
    AccountsAndAddressesNavigationController *navigationController = (AccountsAndAddressesNavigationController *)self.navigationController;
    navigationController.headerLabel.text = self.address ? [app.wallet labelForLegacyAddress:self.address] : [app.wallet getLabelForAccount:self.account];
}

- (void)updateHeaderText:(NSString *)headerText
{
    AccountsAndAddressesNavigationController *navigationController = (AccountsAndAddressesNavigationController *)self.navigationController;
    navigationController.headerLabel.text = headerText;
}

- (void)reload
{
    [self resetHeader];
    [self.tableView reloadData];
}

- (BOOL)isArchived
{
    if (self.address) {
      return [app.wallet isAddressArchived:self.address];
    } else {
      return [app.wallet isAccountArchived:self.account];
    }
}

- (BOOL)canTransferFromAddress
{
#ifdef ENABLE_TRANSFER_FUNDS
    if (self.address) {
        return [app.wallet getLegacyAddressBalance:self.address] > 0 && ![app.wallet isWatchOnlyLegacyAddress:self.address] && ![self isArchived] && [app.wallet didUpgradeToHd];
    } else {
        return NO;
    }
#else
    return NO;
#endif
}

- (void)showBusyViewWithLoadingText:(NSString *)text;
{
    AccountsAndAddressesNavigationController *navigationController = (AccountsAndAddressesNavigationController *)self.navigationController;
    [navigationController showBusyViewWithLoadingText:text];
}

- (void)alertToShowAccountXPub
{
    UIAlertController *alertToShowXPub = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING_TITLE message:BC_STRING_EXTENDED_PUBLIC_KEY_WARNING preferredStyle:UIAlertControllerStyleAlert];
    [alertToShowXPub addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showAccountXPub:self.account];
    }]];
    [alertToShowXPub addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertToShowXPub animated:YES completion:nil];
}

- (void)showDetailScreenWithType:(DetailType)type
{
    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_ACCOUNTS_AND_ADDRESSES_DETAIL_EDIT sender:[NSNumber numberWithInt:type]];
}

- (void)transferFundsFromAddressClicked
{
    [self dismissViewControllerAnimated:YES completion:^{
        [app closeSideMenu];
        app.topViewControllerDelegate = nil;
    }];
    
    if (!app.sendViewController) {
        app.sendViewController = [[SendViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
    }
    
    [app closeSideMenu];
    
    [app showSendCoins];

    [app.sendViewController transferFundsFromAddress:self.address];
}

- (void)labelAddressClicked
{
    [self showDetailScreenWithType:DetailTypeEditAddressLabel];
}

- (void)labelAccountClicked
{
    [self showDetailScreenWithType:DetailTypeEditAccountLabel];
}

- (void)showAddress:(NSString *)address
{
    [self showDetailScreenWithType:DetailTypeShowAddress];
}

- (void)showAccountXPub:(int)account
{
    [self showDetailScreenWithType:DetailTypeShowExtendedPublicKey];
}

- (void)setDefaultAccount:(int)account
{
    [self showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    [app.wallet setDefaultAccount:account];
}

- (void)toggleArchive
{
    if (self.address) {
        
        NSArray *activeLegacyAddresses = [app.wallet activeLegacyAddresses];
        
        if (![app.wallet didUpgradeToHd] && [activeLegacyAddresses count] == 1 && [[activeLegacyAddresses firstObject] isEqualToString:self.address]) {
            [app standardNotifyAutoDismissingController:BC_STRING_AT_LEAST_ONE_ADDRESS_REQUIRED];
        } else {
            [self showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
            [app.wallet toggleArchiveLegacyAddress:self.address];
        }
    } else {
        [self showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
        [app.wallet toggleArchiveAccount:self.account];
    }
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

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_ACCOUNTS_AND_ADDRESSES_DETAIL_EDIT]) {
        
        int detailType = [sender intValue];
        
        if (detailType == DetailTypeEditAddressLabel) {
            
            BCEditAddressView *editAddressView = [[BCEditAddressView alloc] initWithAddress:self.address];
            editAddressView.labelTextField.text = [app.wallet labelForLegacyAddress:self.address];
            
            [self setupModalView:editAddressView inViewController:segue.destinationViewController];
            
            [editAddressView.labelTextField becomeFirstResponder];
            [self updateHeaderText:BC_STRING_LABEL_ADDRESS];
            
        } else if (detailType == DetailTypeEditAccountLabel) {
            
            BCEditAccountView *editAccountView = [[BCEditAccountView alloc] init];
            editAccountView.labelTextField.text = [app.wallet getLabelForAccount:self.account];
            editAccountView.accountIdx = self.account;
            
            [self setupModalView:editAccountView inViewController:segue.destinationViewController];
            
            [editAccountView.labelTextField becomeFirstResponder];
            [self updateHeaderText:BC_STRING_NAME];
            
        } else if (detailType == DetailTypeShowExtendedPublicKey) {
            
            BCQRCodeView *qrCodeView = [[BCQRCodeView alloc] initWithFrame:self.view.frame qrHeaderText:BC_STRING_EXTENDED_PUBLIC_KEY_DETAIL_HEADER_TITLE];
            qrCodeView.address = [app.wallet getXpubForAccount:self.account];
            
            [self setupModalView:qrCodeView inViewController:segue.destinationViewController];
            
            qrCodeView.qrCodeFooterLabel.text = BC_STRING_COPY_XPUB;
            [self updateHeaderText:BC_STRING_EXTENDED_PUBLIC_KEY];

        } else if (detailType == DetailTypeShowAddress) {
            
            BCQRCodeView *qrCodeView = [[BCQRCodeView alloc] initWithFrame:self.view.frame];
            qrCodeView.address = self.address;
            
            [self setupModalView:qrCodeView inViewController:segue.destinationViewController];
            
            qrCodeView.qrCodeFooterLabel.text = BC_STRING_COPY_ADDRESS;
            [self updateHeaderText:BC_STRING_ADDRESS];
        }
    }
}

- (void)setupModalView:(UIView *)modalView inViewController:(UIViewController *)viewController
{
    [viewController.view addSubview:modalView];
    
    CGRect frame = modalView.frame;
    frame.origin.y = viewController.view.frame.origin.y + DEFAULT_HEADER_HEIGHT;
    modalView.frame = frame;
}

#pragma mark Table View Delegate

- (NSString *)tableView:(UITableView *)tableView titleForFooterInSection:(NSInteger)section
{
    BOOL canTransferFromAddress = [self canTransferFromAddress];
    
    int sectionTransfer = -1;
    int sectionMain = 0;
    int sectionArchived = 1;
    
    if (canTransferFromAddress) {
        sectionTransfer = 0;
        sectionMain = 1;
        sectionArchived = 2;
    }
    
    if (section == sectionTransfer) {
        return BC_STRING_TRANSFER_FOOTER_TITLE;
    }
    
    if (section == sectionMain) {
        if ([self isArchived]) {
            return BC_STRING_ARCHIVED_FOOTER_TITLE;
        } else {
            if (self.address) {
                return [app.wallet isWatchOnlyLegacyAddress:self.address] ? BC_STRING_WATCH_ONLY_FOOTER_TITLE : BC_STRING_ARCHIVE_FOOTER_TITLE;
            } else {
                return [NSString stringWithFormat:@"%@\n\n%@", BC_STRING_EXTENDED_PUBLIC_KEY_FOOTER_TITLE_ONE, BC_STRING_EXTENDED_PUBLIC_KEY_FOOTER_TITLE_TWO];
            }
        }
    } else if (section == sectionArchived) {
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
        int numberOfSections = numberOfSectionsAddressUnarchived;
        if ([self canTransferFromAddress]) {
            numberOfSections++;
        }
        return [app.wallet isWatchOnlyLegacyAddress:self.address] ? numberOfSections + 1 : numberOfSections;
    } else {
        return [app.wallet getDefaultAccountIndex] == self.account ? numberOfSectionsAccountUnarchived - 1 : numberOfSectionsAccountUnarchived;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    BOOL canTransferFromAddress = [self canTransferFromAddress];
    
    if (canTransferFromAddress) {
        if (section == 0) {
            if ([self isArchived]) {
                return numberOfRowsArchived;
            } else {
                return numberOfRowsTransfer;
            }
        }
        
        if (section == 1) {
            if (self.address) {
                return numberOfRowsAddressUnarchived;
            } else {
                return [app.wallet getDefaultAccountIndex] == self.account ? numberOfRowsAccountUnarchived - 1 : numberOfRowsAccountUnarchived;
            }
        }
        
        if (section == 2) {
            return numberOfRowsArchived;
        }
    } else {
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
        
        if (section == 1) {
            return numberOfRowsArchived;
        }
    }
    
    return 0;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    BOOL canTransferFromAddress = [self canTransferFromAddress];
    
    int sectionTransfer = -1;
    int sectionMain = 0;
    int sectionArchived = 1;
    
    if (canTransferFromAddress) {
        sectionTransfer = 0;
        sectionMain = 1;
        sectionArchived = 2;
    }
    
    if (indexPath.section == sectionTransfer) {
        switch (indexPath.row) {
            case 0: {
                [self transferFundsFromAddressClicked];
            }
        }
    }
    
    if (indexPath.section == sectionMain) {
        if ([self isArchived]) {
            switch (indexPath.row) {
                case 0: {
                    [self toggleArchive];
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
                            [self alertToShowAccountXPub];
                        }
                    }
                    return;
                }
                case 2: {
                    if (self.address) {
                        if ([app.wallet isWatchOnlyLegacyAddress:self.address]) {
                            [app scanPrivateKeyForWatchOnlyAddress:self.address];
                        } else {
                            [self toggleArchive];
                        }
                    } else {
                        [self alertToShowAccountXPub];
                    }
                        return;
                }
            }
        }
    }
    if (indexPath.section == sectionArchived) {
        [self toggleArchive];
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    cell.textLabel.font = [UIFont fontWithName:FONT_HELVETICA_NUEUE size:15];
    cell.detailTextLabel.font = [UIFont fontWithName:FONT_HELVETICA_NUEUE size:15];
    cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    
    BOOL canTransferFromAddress = [self canTransferFromAddress];
    
    int sectionTransfer = -1;
    int sectionMain = 0;
    int sectionArchived = 1;
    
    if (canTransferFromAddress) {
        sectionTransfer = 0;
        sectionMain = 1;
        sectionArchived = 2;
    }
    
    if (indexPath.section == sectionTransfer) {
        switch (indexPath.row) {
            case 0: {
                cell.textLabel.text = BC_STRING_TRANSFER_FUNDS;
                cell.textLabel.textColor = COLOR_TABLE_VIEW_CELL_TEXT_BLUE;
                cell.detailTextLabel.text = nil;
                cell.accessoryType = UITableViewCellAccessoryNone;
            }
            return cell;
        }
    }
    
    if (indexPath.section == sectionMain) {
        switch (indexPath.row) {
            case 0: {
                if ([self isArchived]) {
                    if ([self isArchived]) {
                        cell.textLabel.text = BC_STRING_UNARCHIVE;
                        cell.textLabel.textColor = COLOR_TABLE_VIEW_CELL_TEXT_BLUE;
                    } else {
                        cell.textLabel.text = BC_STRING_ARCHIVE;
                        cell.textLabel.textColor = [UIColor redColor];
                    }
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
                    if ([app.wallet getDefaultAccountIndex] != self.account) {
                        cell.textLabel.text = BC_STRING_MAKE_DEFAULT;
                        cell.textLabel.textColor = COLOR_TABLE_VIEW_CELL_TEXT_BLUE;
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    } else {
                        cell.textLabel.text = BC_STRING_EXTENDED_PUBLIC_KEY;
                        cell.textLabel.textColor = [UIColor blackColor];
                    }
                }
                return cell;
            }
            case 2: {
                if (self.address) {
                    if ([app.wallet isWatchOnlyLegacyAddress:self.address]) {
                        cell.textLabel.text = BC_STRING_SCAN_PRIVATE_KEY;
                        cell.textLabel.textColor = COLOR_TABLE_VIEW_CELL_TEXT_BLUE;
                        cell.accessoryType = UITableViewCellAccessoryNone;
                    } else {
                        if ([self isArchived]) {
                            cell.textLabel.text = BC_STRING_UNARCHIVE;
                            cell.textLabel.textColor = COLOR_TABLE_VIEW_CELL_TEXT_BLUE;
                        } else {
                            cell.textLabel.text = BC_STRING_ARCHIVE;
                            cell.textLabel.textColor = [UIColor redColor];
                        }
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
    if (indexPath.section == sectionArchived) {
        if ([self isArchived]) {
            cell.textLabel.text = BC_STRING_UNARCHIVE;
            cell.textLabel.textColor = COLOR_TABLE_VIEW_CELL_TEXT_BLUE;
        } else {
            cell.textLabel.text = BC_STRING_ARCHIVE;
            cell.textLabel.textColor = [UIColor redColor];
        }
        return cell;
    }
    return nil;
}

@end

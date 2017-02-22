//
//  AccountsAndAddressesViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 1/12/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "AccountsAndAddressesViewController.h"
#import "AccountsAndAddressesDetailViewController.h"
#import "RootService.h"
#import "ReceiveTableCell.h"
#import "BCCreateAccountView.h"
#import "BCModalViewController.h"
#import "PrivateKeyReader.h"
#import "UIViewController+AutoDismiss.h"
#import "Blockchain-Swift.h"

@interface AccountsAndAddressesViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) NSString *clickedAddress;
@property (nonatomic) int clickedAccount;
@end

@implementation AccountsAndAddressesViewController

@synthesize allKeys;

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.tableView = [[UITableView alloc] initWithFrame:app.window.frame style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reload) name:NOTIFICATION_KEY_RELOAD_ACCOUNTS_AND_ADDRESSES object:nil];
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    AccountsAndAddressesNavigationController *navigationController = (AccountsAndAddressesNavigationController *)self.navigationController;
    navigationController.headerLabel.text = BC_STRING_ADDRESSES;
    
    if ([[UIScreen mainScreen] bounds].size.height <= HEIGHT_IPHONE_4S) {
        self.edgesForExtendedLayout = UIRectEdgeNone;
    }

    [self displayTransferFundsWarningIfAppropriate];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    AccountsAndAddressesNavigationController *navigationController = (AccountsAndAddressesNavigationController *)self.navigationController;
    navigationController.warningButton.hidden = YES;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)reload
{
    allKeys = [app.wallet allLegacyAddresses];
    [self.tableView reloadData];
    
    [self displayTransferFundsWarningIfAppropriate];
}

#pragma mark - Navigation

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:SEGUE_IDENTIFIER_ACCOUNTS_AND_ADDRESSES_DETAIL]) {
        AccountsAndAddressesDetailViewController *detailViewController = segue.destinationViewController;
        if (self.clickedAddress) {
            detailViewController.address = self.clickedAddress;
            detailViewController.account = -1;
        } else if (self.clickedAccount >= 0) {
            detailViewController.account = self.clickedAccount;
            detailViewController.address = nil;
        }
    }
}

#pragma mark - Actions

- (void)didSelectAddress:(NSString *)address
{
    self.clickedAddress = address;
    self.clickedAccount = -1;
    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_ACCOUNTS_AND_ADDRESSES_DETAIL sender:nil];
}

- (void)didSelectAccount:(int)account
{
    self.clickedAccount = account;
    self.clickedAddress = nil;
    [self performSegueWithIdentifier:SEGUE_IDENTIFIER_ACCOUNTS_AND_ADDRESSES_DETAIL sender:nil];
}

#pragma mark - Helpers

- (void)newAccountClicked:(id)sender
{
    BCCreateAccountView *createAccountView = [[BCCreateAccountView alloc] init];
    
    BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:BC_STRING_CREATE view:createAccountView];
    
    [self presentViewController:modalViewController animated:YES completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [createAccountView.labelTextField becomeFirstResponder];
    });
}

- (void)newAddressClicked:(id)sender
{
    if ([app.wallet didUpgradeToHd]) {
        [self importAddress];
    } else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:BC_STRING_NEW_ADDRESS message:nil preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *generateNewAddressAction = [UIAlertAction actionWithTitle:BC_STRING_NEW_ADDRESS_CREATE_NEW style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self generateNewAddress];
        }];
        UIAlertAction *importAddressAction = [UIAlertAction actionWithTitle:BC_STRING_IMPORT_ADDRESS style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self importAddress];
        }];
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        }];
        
        [alertController addAction:generateNewAddressAction];
        [alertController addAction:importAddressAction];
        [alertController addAction:cancelAction];
        
        [self presentViewController:alertController animated:YES completion:^{
            [[NSNotificationCenter defaultCenter] addObserver:alertController
                                                     selector:@selector(autoDismiss)
                                                         name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS
                                                       object:nil];
        }];
    }
}

- (void)generateNewAddress
{
    if (![app checkInternetConnection]) {
        return;
    }
    
    [app.wallet generateNewKey];
}

- (void)didGenerateNewAddress
{
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(promptForLabelAfterGenerate)
                                                 name:NOTIFICATION_KEY_NEW_ADDRESS object:nil];
}

- (void)promptForLabelAfterGenerate
{
    //newest address is the last object in activeKeys
    self.clickedAddress = [allKeys lastObject];
    [self didSelectAddress:self.clickedAddress];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_NEW_ADDRESS
                                                  object:nil];
}

- (void)importAddress
{
    if (![app checkInternetConnection]) {
        return;
    }
    
    if (![app getCaptureDeviceInput]) {
        return;
    }
    
    PrivateKeyReader *reader = [[PrivateKeyReader alloc] initWithSuccess:^(NSString* keyString) {
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(promptForLabelAfterScan)
                                                     name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
        [app.wallet addKey:keyString];
    } error:nil acceptPublicKeys:YES busyViewText:BC_STRING_LOADING_IMPORT_KEY];
    
    [[NSNotificationCenter defaultCenter] addObserver:reader selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    
    [self presentViewController:reader animated:YES completion:nil];
}

- (void)promptForLabelAfterScan
{
    //newest address is the last object in activeKeys
    self.clickedAddress = [allKeys lastObject];
    [self didSelectAddress:self.clickedAddress];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_BACKUP_SUCCESS
                                                  object:nil];
}

- (void)displayTransferFundsWarningIfAppropriate
{
    AccountsAndAddressesNavigationController *navigationController = (AccountsAndAddressesNavigationController *)self.navigationController;
    
    if ([app.wallet didUpgradeToHd] && [app.wallet getTotalBalanceForSpendableActiveLegacyAddresses] >= [app.wallet dust] && navigationController.visibleViewController == self) {
        navigationController.warningButton.hidden = NO;
    } else {
        navigationController.warningButton.hidden = YES;
    }
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 44.0f;
    }
    
    return 70.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        if (![app.wallet isInitialized]) {
            return 45.0f;
        } else {
            if ([app.wallet didUpgradeToHd]) {
                return 45.0f;
            } else {
                return 0;
            }
        }
    } else {
        return 45.0f;
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    if ([[UIScreen mainScreen] bounds].size.height <= HEIGHT_IPHONE_4S && section == [tableView numberOfSections] - 1) {
        return DEFAULT_HEADER_HEIGHT;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 45)];
    view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width, 14)];
    label.textColor = COLOR_BLOCKCHAIN_BLUE;
    label.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:14.0];
    
    [view addSubview:label];
    
    NSString *labelString;
    
    if (section == 0) {
        labelString = BC_STRING_WALLETS;
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20 - 30, 4, 50, 40)];
        [addButton setImage:[[UIImage imageNamed:@"new"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        addButton.imageView.tintColor = COLOR_BLOCKCHAIN_BLUE;
        [addButton addTarget:self action:@selector(newAccountClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:addButton];
    }
    else if (section == 1) {
        labelString = BC_STRING_IMPORTED_ADDRESSES;
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20 - 30, 4, 50, 40)];
        [addButton setImage:[[UIImage imageNamed:@"new"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        addButton.imageView.tintColor = COLOR_BLOCKCHAIN_BLUE;
        [addButton addTarget:self action:@selector(newAddressClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:addButton];
    } else
        @throw @"Unknown Section";
    
    label.text = labelString;
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return [app.wallet getAllAccountsCount];
    else if (section == 1)
        return [allKeys count];
    return 0;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    if (indexPath.section == 0) {
        [self didSelectAccount:(int)indexPath.row];
    } else if (indexPath.section == 1) {
        [self didSelectAddress:allKeys[indexPath.row]];
    }
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        int accountIndex = (int) indexPath.row;
        NSString *accountLabelString = [app.wallet getLabelForAccount:accountIndex];
        
        ReceiveTableCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"receiveAccount"];
        
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
            cell.backgroundColor = [UIColor whiteColor];
            
            if ([app.wallet getDefaultAccountIndex] == accountIndex) {
                
                cell.labelLabel.frame = CGRectMake(20, 11, 155, 21);
                cell.balanceLabel.frame = CGRectMake(247, 11, 90, 21);
                UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 217, cell.frame.size.height-(cell.frame.size.height-cell.balanceLabel.frame.origin.y-cell.balanceLabel.frame.size.height), 0);
                cell.balanceButton.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, contentInsets);
                
                cell.watchLabel.hidden = NO;
                cell.watchLabel.text = BC_STRING_DEFAULT;
                cell.watchLabel.textColor = [UIColor grayColor];
            } else {
                
                // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
                cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
                cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
                UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 217, cell.frame.size.height-(cell.frame.size.height-cell.balanceLabel.frame.origin.y-cell.balanceLabel.frame.size.height), 0);
                cell.balanceButton.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, contentInsets);
                
                cell.watchLabel.hidden = YES;
                cell.watchLabel.text = BC_STRING_WATCH_ONLY;
                cell.watchLabel.textColor = [UIColor redColor];
            }
        }
        
        cell.labelLabel.text = accountLabelString;
        cell.addressLabel.text = @"";
        
        uint64_t balance = [app.wallet getBalanceForAccount:accountIndex];
        
        // Selected cell color
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
        [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
        [cell setSelectedBackgroundView:v];
        
        if ([app.wallet isAccountArchived:accountIndex]) {
            cell.balanceLabel.text = BC_STRING_ARCHIVED;
            cell.balanceLabel.textColor = COLOR_BUTTON_BLUE;
        } else {
            cell.balanceLabel.text = [NSNumberFormatter formatMoney:balance];
            cell.balanceLabel.textColor = COLOR_BLOCKCHAIN_GREEN;
        }
        cell.balanceLabel.minimumScaleFactor = 0.75f;
        [cell.balanceLabel setAdjustsFontSizeToFitWidth:YES];
        
        [cell.balanceButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
    
    NSString *addr = [allKeys objectAtIndex:[indexPath row]];
    
    Boolean isWatchOnlyLegacyAddress = [app.wallet isWatchOnlyLegacyAddress:addr];
    
    ReceiveTableCell *cell;
    if (isWatchOnlyLegacyAddress) {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"receiveWatchOnly"];
    }
    else {
        cell = [self.tableView dequeueReusableCellWithIdentifier:@"receiveNormal"];
    }
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
        cell.backgroundColor = COLOR_BACKGROUND_GRAY;
        
        if (isWatchOnlyLegacyAddress) {
            // Show the watch only tag and resize the label and balance labels so there is enough space
            cell.labelLabel.frame = CGRectMake(20, 11, 148, 21);
            
            cell.balanceLabel.frame = CGRectMake(254, 11, 83, 21);
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 254, cell.frame.size.height-(cell.frame.size.height-cell.balanceLabel.frame.origin.y-cell.balanceLabel.frame.size.height), 0);
            cell.balanceButton.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, contentInsets);
            
            [cell.watchLabel setHidden:FALSE];
        }
        else {
            // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
            cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
            
            cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 217, cell.frame.size.height-(cell.frame.size.height-cell.balanceLabel.frame.origin.y-cell.balanceLabel.frame.size.height), 0);
            cell.balanceButton.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, contentInsets);
            
            [cell.watchLabel setHidden:TRUE];
        }
    }
    
    NSString *label =  [app.wallet labelForLegacyAddress:addr];
    
    if (label)
        cell.labelLabel.text = label;
    else
        cell.labelLabel.text = BC_STRING_NO_LABEL;
    
    cell.addressLabel.text = addr;
    
    uint64_t balance = [app.wallet getLegacyAddressBalance:addr];
    
    // Selected cell color
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    [cell setSelectedBackgroundView:v];
    
    if ([app.wallet isAddressArchived:addr]) {
        cell.balanceLabel.text = BC_STRING_ARCHIVED;
        cell.balanceLabel.textColor = COLOR_BUTTON_BLUE;
    } else {
        cell.balanceLabel.text = [NSNumberFormatter formatMoney:balance];
        cell.balanceLabel.textColor = COLOR_LABEL_BALANCE_GREEN;
    }
    cell.balanceLabel.minimumScaleFactor = 0.75f;
    [cell.balanceLabel setAdjustsFontSizeToFitWidth:YES];
    
    [cell.balanceButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

@end

//
//  ContactDetailViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/7/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactDetailViewController.h"
#import "Contact.h"
#import "BCNavigationController.h"
#import "BCQRCodeView.h"
#import "Blockchain-Swift.h"
#import "BCContactRequestView.h"
#import "TransactionTableCell.h"
#import "ContactTransactionTableViewCell.h"
#import "TransactionDetailViewController.h"
#import "TransactionDetailNavigationController.h"
#import "RootService.h"

const int sectionMain = 0;
const int rowName = 0;
const int rowExtendedPublicKey = 1;
const int rowTrust = 2;
const int rowFetchMDID = 3;

const int maxFindAttempts = 2;

@interface ContactDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) BCNavigationController *contactRequestNavigationController;
@property (nonatomic) TransactionDetailViewController *transactionDetailViewController;
@property (nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic) NSArray *transactionList;

@end

@implementation ContactDetailViewController

#pragma mark - Lifecycle

- (id)initWithContact:(Contact *)contact
{
    if (self = [super init]) {
        _contact = contact;
        [self setupTransactionList];
    }
    return self;
}

- (void)setupTransactionList
{
    NSMutableArray *mutableTransactionList = [NSMutableArray new];
    
    for (ContactTransaction *contactTransaction in [self.contact.transactionList allValues]) {
        if (contactTransaction.transactionState == ContactTransactionStateCompletedSend ||
            contactTransaction.transactionState == ContactTransactionStateCompletedReceive) {
            Transaction *transaction = [self getTransactionDetails:contactTransaction];
            transaction.contactName = self.contact.name;
            if (transaction) [mutableTransactionList addObject:transaction];
        }
    }
    
    self.transactionList = [[NSArray alloc] initWithArray:mutableTransactionList];
    
    [self.tableView reloadData];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - DEFAULT_HEADER_HEIGHT) style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    
    [self.tableView reloadData];
    
    [self setupPullToRefresh];
}

- (void)setContact:(Contact *)contact
{
    _contact = contact;
    
    [self setupTransactionList];
    [self updateNavigationTitle];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self updateNavigationTitle];
}

- (void)updateNavigationTitle
{
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    navigationController.headerTitle = self.contact.name ? self.contact.name : self.contact.identifier;
}

#pragma mark - Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == sectionMain) {
        return self.transactionList.count;
    }
    
    DLog(@"Invalid section");
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Transaction *transaction = [self.transactionList objectAtIndex:indexPath.row];

    TransactionTableCell * cell = (TransactionTableCell*)[tableView dequeueReusableCellWithIdentifier:@"transaction"];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"TransactionCell" owner:nil options:nil] objectAtIndex:0];
    }
    
    cell.transaction = transaction;
    
    [cell reload];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TransactionTableCell *cell = (TransactionTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell transactionClicked:nil indexPath:indexPath];
    self.transactionDetailViewController = app.transactionsViewController.detailViewController;
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == sectionMain) {
        return 96;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == sectionMain) {
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 160)];
        
        CGFloat smallButtonWidth = self.view.frame.size.width/2 - 20 - 5;
        
        UIButton *renameButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 8, smallButtonWidth, 40)];
        [renameButton setTitle:BC_STRING_RENAME_CONTACT forState:UIControlStateNormal];
        renameButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:13];
        renameButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        renameButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        renameButton.backgroundColor = COLOR_BUTTON_BLUE;
        [renameButton addTarget:self action:@selector(renameContact) forControlEvents:UIControlEventTouchUpInside];
        renameButton.layer.cornerRadius = 4;
        [view addSubview:renameButton];
        
        UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 + 5, 8, smallButtonWidth, 40)];
        [deleteButton setTitle:BC_STRING_DELETE_CONTACT forState:UIControlStateNormal];
        deleteButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:13];
        deleteButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        deleteButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        deleteButton.backgroundColor = COLOR_BUTTON_RED;
        deleteButton.layer.cornerRadius = 4;
        [deleteButton addTarget:self action:@selector(confirmDeleteContact) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:deleteButton];
        
        UILabel *label = [[UILabel alloc] init];
        label.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:14.0];
        label.textColor = COLOR_BLOCKCHAIN_BLUE;
        label.frame = CGRectMake(20, renameButton.frame.origin.y + renameButton.frame.size.height + 26, self.view.frame.size.width - 40, 14);

        if (self.transactionList.count > 0) {
            label.text = [BC_STRING_COMPLETED_TRANSACTIONS uppercaseString];
        } else {
            label.textAlignment = NSTextAlignmentCenter;
            label.text = [NSString stringWithFormat:BC_STRING_NO_TRANSACTIONS_WITH_ARGUMENT_YET, self.contact.name];
        }
        

        [view addSubview:label];
        
        return view;
    }
    return nil;
}

#pragma mark - Text Field Delegate

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField.tag == TAG_TEXTFIELD_CHANGE_CONTACT_NAME) {
        [app.wallet changeName:textField.text forContact:self.contact.identifier];
    }
    
    return YES;
}

#pragma mark - Actions

- (void)renameContact
{
    UIAlertController *alertForChangingName = [UIAlertController alertControllerWithTitle:BC_STRING_CHANGE_NAME message:nil preferredStyle:UIAlertControllerStyleAlert];
    
    [alertForChangingName addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        secureTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        secureTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        secureTextField.delegate = self;
        secureTextField.returnKeyType = UIReturnKeyDone;
        secureTextField.tag = TAG_TEXTFIELD_CHANGE_CONTACT_NAME;
        secureTextField.text = self.contact.name;
    }];
    [alertForChangingName addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *newName = [[alertForChangingName textFields] firstObject].text;
        [app.wallet changeName:newName forContact:self.contact.identifier];
    }]];
    [alertForChangingName addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertForChangingName animated:YES completion:nil];
}

- (void)showExtendedPublicKey
{
    BCQRCodeView *qrCodeView = [[BCQRCodeView alloc] initWithFrame:self.view.frame qrHeaderText:nil addAddressPrefix:NO];
    qrCodeView.address = self.contact.xpub;
    
    UIViewController *viewController = [UIViewController new];
    [viewController.view addSubview:qrCodeView];
    
    CGRect frame = qrCodeView.frame;
    frame.origin.y = viewController.view.frame.origin.y + DEFAULT_HEADER_HEIGHT;
    qrCodeView.frame = frame;

    qrCodeView.qrCodeFooterLabel.text = BC_STRING_COPY_XPUB;

    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    navigationController.headerLabel.text = BC_STRING_EXTENDED_PUBLIC_KEY;
    
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)confirmDeleteContact
{
    UIAlertController *alertForDeletingContact = [UIAlertController alertControllerWithTitle:BC_STRING_DELETE_CONTACT_ALERT_TITLE message:BC_STRING_DELETE_CONTACT_ALERT_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
    [alertForDeletingContact addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [app.wallet deleteContact:self.contact.identifier];
    }]];
    [alertForDeletingContact addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertForDeletingContact animated:YES completion:nil];
}

- (Transaction *)getTransactionDetails:(ContactTransaction *)contactTransaction
{
    for (Transaction *transaction in app.latestResponse.transactions) {
        if ([transaction.myHash isEqualToString:contactTransaction.myHash]) {
            return transaction;
        }
    }
    return nil;
}

- (void)didGetMessages:(Contact *)contact
{
    self.contact = contact;
    
    [self.tableView reloadData];
    [self.transactionDetailViewController didGetHistory];
    
    if (self.refreshControl && self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)refreshControlActivated
{
    [app.topViewControllerDelegate showBusyViewWithLoadingText:BC_STRING_LOADING_LOADING_TRANSACTIONS];
    [app.wallet performSelector:@selector(getHistory) withObject:nil afterDelay:0.1f];
}

- (void)setupPullToRefresh
{
    // Tricky way to get the refreshController to work on a UIViewController - @see http://stackoverflow.com/a/12502450/2076094
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl setTintColor:[UIColor grayColor]];
    [self.refreshControl addTarget:self
                            action:@selector(refreshControlActivated)
                  forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
}

- (void)reloadSymbols
{
    [self.tableView reloadData];
    [self.transactionDetailViewController reloadSymbols];
}

@end

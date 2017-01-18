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
#import "ContactTransactionTableViewCell.h"
#import "ContactTransaction.h"
#import "TransactionDetailViewController.h"

const int sectionMain = 0;
const int rowName = 0;
const int rowExtendedPublicKey = 1;
const int rowTrust = 2;
const int rowFetchMDID = 3;

typedef enum {
    RequestTypeSendReason,
    RequestTypeReceiveReason,
    RequestTypeSendAmount,
    RequestTypeReceiveAmount
} RequestType;

@interface ContactDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, ContactRequestDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) BCNavigationController *contactRequestNavigationController;
@end

@implementation ContactDetailViewController

#pragma mark - Lifecycle

- (id)initWithContact:(Contact *)contact
{
    if (self = [super init]) {
        _contact = contact;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[ContactTransactionTableViewCell class] forCellReuseIdentifier:CELL_IDENTIFIER_CONTACT_TRANSACTION];
    
    [self.tableView reloadData];
}

- (void)setContact:(Contact *)contact
{
    _contact = contact;
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
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
        return self.contact.transactionList.count;
    }
    
    DLog(@"Invalid section");
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactTransactionTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_CONTACT_TRANSACTION forIndexPath:indexPath];
    
    NSDictionary *dictionary = [[self.contact.transactionList allValues] objectAtIndex:indexPath.row];
    
    ContactTransaction *transaction = [[ContactTransaction alloc] initWithDictionary:dictionary];
    
    [cell configureWithTransaction:transaction contactName:self.contact.name];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *dictionary = [[self.contact.transactionList allValues] objectAtIndex:indexPath.row];
    
    ContactTransaction *transaction = [[ContactTransaction alloc] initWithDictionary:dictionary];
    
    if (transaction.transactionState == ContactTransactionStateReceiveAcceptOrDenyPayment) {
        [self acceptOrDenyPayment:transaction];
    } else if (transaction.transactionState == ContactTransactionStateSendReadyToSend) {
        [self sendPayment:transaction];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == sectionMain) {
        return 250;
    }
    return 0;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == sectionMain) {
        
        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 160)];
        
        UILabel *promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(8, 8, self.view.frame.size.width, 30)];
        promptLabel.text = BC_STRING_I_WANT_TO_COLON;
        [view addSubview:promptLabel];
        
        UIButton *sendButton = [[UIButton alloc] initWithFrame:CGRectMake(20, promptLabel.frame.origin.y + promptLabel.frame.size.height + 8, self.view.frame.size.width - 40, 50)];
        [sendButton setTitle:[NSString stringWithFormat:BC_STRING_ASK_TO_SEND_ARGUMENT_BITCOIN, self.contact.name] forState:UIControlStateNormal];
        sendButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        sendButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        sendButton.backgroundColor = COLOR_BUTTON_RED;
        [sendButton addTarget:self action:@selector(sendClicked) forControlEvents:UIControlEventTouchUpInside];
        sendButton.layer.cornerRadius = 4;
        [view addSubview:sendButton];
        
        UIButton *requestButton = [[UIButton alloc] initWithFrame:CGRectMake(20, sendButton.frame.origin.y + sendButton.frame.size.height + 8,  self.view.frame.size.width - 40, 50)];
        requestButton.backgroundColor = COLOR_BUTTON_GREEN;
        [requestButton setTitle:[NSString stringWithFormat:BC_STRING_REQUEST_BITCOIN_FROM_ARGUMENT, self.contact.name] forState:UIControlStateNormal];
        requestButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        requestButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        [requestButton addTarget:self action:@selector(requestClicked) forControlEvents:UIControlEventTouchUpInside];
        requestButton.layer.cornerRadius = 4;
        [view addSubview:requestButton];
        
        CGFloat smallButtonWidth = self.view.frame.size.width/2 - 20 - 5;
        
        UIButton *renameButton = [[UIButton alloc] initWithFrame:CGRectMake(20, requestButton.frame.origin.y + requestButton.frame.size.height + 8, smallButtonWidth, 40)];
        [renameButton setTitle:BC_STRING_RENAME_CONTACT forState:UIControlStateNormal];
        renameButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        renameButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        renameButton.backgroundColor = COLOR_BUTTON_BLUE;
        [renameButton addTarget:self action:@selector(renameContact) forControlEvents:UIControlEventTouchUpInside];
        renameButton.layer.cornerRadius = 4;
        [view addSubview:renameButton];
        
        UIButton *deleteButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width/2 + 5, renameButton.frame.origin.y, smallButtonWidth, 40)];
        [deleteButton setTitle:BC_STRING_DELETE_CONTACT forState:UIControlStateNormal];
        deleteButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        deleteButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        deleteButton.backgroundColor = COLOR_BUTTON_RED;
        deleteButton.layer.cornerRadius = 4;
        [deleteButton addTarget:self action:@selector(confirmDeleteContact) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:deleteButton];
        
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, renameButton.frame.origin.y + renameButton.frame.size.height + 26, self.view.frame.size.width, 14)];
        label.textColor = COLOR_FOREGROUND_GRAY;
        label.font = [UIFont systemFontOfSize:14.0];
        label.text = [[NSString stringWithFormat:BC_STRING_TRANSACTIONS_WITH_ARGUMENT, self.contact.name] uppercaseString];

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

- (void)toggleTrust
{
    BOOL trusted = self.contact.trusted;
    
    NSString *title = trusted ? BC_STRING_UNTRUST_USER_ALERT_TITLE : BC_STRING_TRUST_USER_ALERT_TITLE;
    NSString *message = trusted ? BC_STRING_UNTRUST_USER_ALERT_MESSAGE : BC_STRING_TRUST_USER_ALERT_MESSAGE;
    
    UIAlertController *alertForTogglingTrust = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertForTogglingTrust addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        trusted ? [app.wallet deleteTrust:self.contact.identifier] : [app.wallet addTrust:self.contact.identifier];
    }]];
    [alertForTogglingTrust addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        NSIndexPath *indexPath = [NSIndexPath indexPathForRow:rowTrust inSection:0];
        [self.tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }]];
    [self presentViewController:alertForTogglingTrust animated:YES completion:nil];
}

- (void)confirmDeleteContact
{
    UIAlertController *alertForDeletingContact = [UIAlertController alertControllerWithTitle:BC_STRING_DELETE_CONTACT_ALERT_TITLE message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertForDeletingContact addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [app.wallet deleteContact:self.contact.identifier];
    }]];
    [alertForDeletingContact addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertForDeletingContact animated:YES completion:nil];
}

- (void)sendClicked
{
    [self createRequest:RequestTypeSendReason title:BC_STRING_SEND reason:nil];
}

- (void)requestClicked
{
    [self createRequest:RequestTypeReceiveReason title:BC_STRING_RECEIVE reason:nil];
}

- (void)createRequest:(RequestType)requestType title:(NSString *)title reason:(NSString *)reason;
{
    BOOL willSend;
    if (requestType == RequestTypeSendReason || requestType == RequestTypeSendAmount) {
        willSend = YES;
    } else if (requestType == RequestTypeReceiveReason || requestType == RequestTypeReceiveAmount) {
        willSend = NO;
    } else {
        DLog(@"Unknown request type");
        return;
    }
    
    BCContactRequestView *contactRequestView = [[BCContactRequestView alloc] initWithContactName:self.contact.name reason:reason willSend:willSend];
    contactRequestView.delegate = self;
    
    BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:nil view:contactRequestView];
    
    if (requestType == RequestTypeSendReason || requestType == RequestTypeReceiveReason) {
        self.contactRequestNavigationController = [[BCNavigationController alloc] initWithRootViewController:modalViewController title:title];
        [self presentViewController:self.contactRequestNavigationController animated:YES completion:nil];
    } else {
        [self.contactRequestNavigationController pushViewController:modalViewController animated:YES];
    }
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [contactRequestView showKeyboard];
    });
}

- (void)acceptOrDenyPayment:(ContactTransaction *)transaction
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil message:[NSString stringWithFormat:BC_STRING_ARGUMENT_WANTS_TO_SEND_YOU_ARGUMENT, self.contact.name, [NSNumberFormatter formatMoney:transaction.intendedAmount localCurrency:NO]] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_ACCEPT style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [app.wallet sendPaymentRequest:self.contact.identifier amount:transaction.intendedAmount requestId:transaction.identifier note:transaction.note];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)sendPayment:(ContactTransaction *)transaction
{
    [self dismissViewControllerAnimated:YES completion:^{
        [app setupPaymentAmount:transaction.intendedAmount toAddress:transaction.address];
    }];
}

- (void)didGetMessages
{
    [self.tableView reloadData];
}

- (void)didReadMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_MESSAGE message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)didSendMessage:(NSString *)contact
{
    [self dismissViewControllerAnimated:YES completion:^{
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_MESSAGE_SENT message:nil preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        [self presentViewController:alert animated:YES completion:nil];
    }];
}

#pragma mark - Contact Request Delegate

- (void)promptRequestAmount:(NSString *)reason
{
    [self createRequest:RequestTypeReceiveAmount title:BC_STRING_RECEIVE reason:reason];
}

- (void)promptSendAmount:(NSString *)reason
{
    [self createRequest:RequestTypeSendAmount title:BC_STRING_RECEIVE reason:reason];
}

- (void)createSendRequestWithReason:(NSString *)reason amount:(uint64_t)amount
{
    DLog(@"Creating send request with reason: %@, amount: %lld", reason, amount);
    
    [app.wallet requestPaymentRequest:self.contact.identifier amount:amount requestId:nil note:reason];
}

- (void)createReceiveRequestWithReason:(NSString *)reason amount:(uint64_t)amount
{
    DLog(@"Creating receive request with reason: %@, amount: %lld", reason, amount);
    
    [app.wallet sendPaymentRequest:self.contact.identifier amount:amount requestId:nil note:reason];
}

@end

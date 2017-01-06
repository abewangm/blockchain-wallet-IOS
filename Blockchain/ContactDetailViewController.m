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

const int sectionMain = 0;
const int rowName = 0;
const int rowExtendedPublicKey = 1;
const int rowTrust = 2;
const int rowFetchMDID = 3;

const int sectionDelete = 1;
const int rowDelete = 0;

@interface ContactDetailViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate>
@property (nonatomic) UITableView *tableView;
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
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CELL_IDENTIFIER_CONTACT_DETAIL];
    
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
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == sectionMain) {
        return self.contact.invitationSent ? 4 : 3;
    } else if (section == sectionDelete) {
        return 1;
    }
    
    DLog(@"Invalid section");
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_CONTACT_DETAIL forIndexPath:indexPath];

    if (indexPath.section == sectionMain) {
        
        cell.textLabel.textColor = [UIColor blackColor];
        
        if (indexPath.row == rowName) {
            cell.textLabel.text = self.contact.name ? self.contact.name : self.contact.identifier;
            cell.accessoryView = nil;
        } else if (indexPath.row == rowExtendedPublicKey) {
            cell.textLabel.text = BC_STRING_EXTENDED_PUBLIC_KEY;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else if (indexPath.row == rowTrust) {
            cell.textLabel.text = BC_STRING_TRUST_USER;
            UISwitch *switchForTrust = [[UISwitch alloc] init];
            switchForTrust.on = self.contact.trusted;
            [switchForTrust addTarget:self action:@selector(toggleTrust) forControlEvents:UIControlEventTouchUpInside];
            cell.accessoryView = switchForTrust;
        } else if (indexPath.row == rowFetchMDID) {
            cell.textLabel.text = BC_STRING_FETCH_MDID;
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        } else {
            DLog(@"Invalid row for main section");
            return nil;
        }
    } else if (indexPath.section == sectionDelete) {
        if (indexPath.row == rowDelete) {
            cell.textLabel.textColor = [UIColor redColor];
            cell.textLabel.text = BC_STRING_DELETE_CONTACT;
            cell.accessoryView = nil;
        } else {
            DLog(@"Invalid row for delete section");
            return nil;
        }
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.section == sectionMain) {
        if (indexPath.row == rowName) {
            [self changeContactName];
        } else if (indexPath.row == rowExtendedPublicKey) {
            if (!self.contact.xpub) {
                [app.wallet fetchExtendedPublicKey:self.contact.identifier];
            } else {
                [self showExtendedPublicKey];
            }
        } else if (indexPath.row == rowFetchMDID) {
            [app.wallet completeRelation:self.contact.identifier];
        } else {
            DLog(@"Invalid selected row for main section");
        }
    } else if (indexPath.section == sectionDelete) {
        if (indexPath.row == rowDelete) {
            [self confirmDeleteContact];
        } else {
            DLog(@"Invalid selected row for delete section");
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == sectionMain) {
        return 160;
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
        sendButton.backgroundColor = COLOR_BUTTON_RED;
        [sendButton addTarget:self action:@selector(sendClicked) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:sendButton];
        
        UIButton *requestButton = [[UIButton alloc] initWithFrame:CGRectMake(20, sendButton.frame.origin.y + sendButton.frame.size.height + 8,  self.view.frame.size.width - 40, 50)];
        requestButton.backgroundColor = COLOR_BUTTON_GREEN;
        [requestButton setTitle:[NSString stringWithFormat:BC_STRING_REQUEST_BITCOIN_FROM_ARGUMENT, self.contact.name] forState:UIControlStateNormal];
        [requestButton addTarget:self action:@selector(requestClicked) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:requestButton];
        
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

- (void)changeContactName
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
    [self dismissViewControllerAnimated:YES completion:^{
        [app closeSideMenu];
        [app performSelector:@selector(showSendCoins) withObject:nil afterDelay:ANIMATION_DURATION];
    }];
}

- (void)requestClicked
{
    
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

@end

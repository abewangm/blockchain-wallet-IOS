//
//  ContactsViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 11/1/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactsViewController.h"
#import "BCCreateContactView.h"
#import "BCModalViewController.h"
#import "Blockchain-Swift.h"
#import "Invitation.h"
#import "BCQRCodeView.h"
#import "NSString+NSString_EscapeQuotes.h"
#import "Contact.h"
#import "ContactMessagesViewController.h"

const int sectionContacts = 0;

@interface ContactsViewController () <UITableViewDelegate, UITableViewDataSource, AVCaptureMetadataOutputObjectsDelegate>

@property (nonatomic) BCNavigationController *createContactNavigationController;
@property (nonatomic) ContactMessagesViewController *messagesViewController;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *contacts;

@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@end

@implementation ContactsViewController

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.view addSubview:self.tableView];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CELL_IDENTIFIER_CONTACT];
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CELL_IDENTIFIER_INVITATION];
    
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    navigationController.headerTitle = BC_STRING_CONTACTS;
}

- (void)reload
{
    self.contacts = [self getContacts];
    
    [app.wallet getMessages];
    
    [self.tableView reloadData];
}

- (NSArray *)getContacts
{
    NSArray *contactsArray = [[app.wallet getContacts] allValues];
    NSMutableArray *contacts = [NSMutableArray new];
    for (NSDictionary *contactDict in contactsArray) {
        Contact *contact = [[Contact alloc] initWithDictionary:contactDict];
        [contacts addObject:contact];
    }
    return contacts;
}

- (void)updateContactDetail
{
    [self reload];
    
    NSString *contactIdentifier = self.messagesViewController.contact.identifier;
    
    Contact *reloadedContact = [[Contact alloc] initWithDictionary:[[app.wallet getContacts] objectForKey:contactIdentifier]];
    
    self.messagesViewController.contact = reloadedContact;
}

#pragma mark - Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.contacts.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_CONTACT forIndexPath:indexPath];
    
    Contact *contact = self.contacts[indexPath.row];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = contact.name ? contact.name : contact.identifier;
    cell.backgroundColor = COLOR_BACKGROUND_GRAY;
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Contact *contact = self.contacts[indexPath.row];
    [self contactClicked:contact];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 45)];
    view.backgroundColor = [UIColor whiteColor];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width, 14)];
    label.textColor = COLOR_FOREGROUND_GRAY;
    label.font = [UIFont systemFontOfSize:14.0];
    
    [view addSubview:label];
    
    NSString *labelString;
    
    if (section == 0) {
        labelString = BC_STRING_CONTACTS;
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20 - 30, 4, 50, 40)];
        [addButton setImage:[UIImage imageNamed:@"new-grey"] forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(newContactClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:addButton];
    }
    
    label.text = [labelString uppercaseString];
    
    return view;
}

#pragma mark - Actions

- (void)contactClicked:(Contact *)contact
{
    self.messagesViewController = [[ContactMessagesViewController alloc] initWithContact:contact messages:app.wallet.messages];
    [self.navigationController pushViewController:self.messagesViewController animated:YES];
}

- (void)newContactClicked:(id)sender
{
    UIAlertController *createContactOptionsAlert = [UIAlertController alertControllerWithTitle:BC_STRING_NEW_CONTACT message:nil preferredStyle:UIAlertControllerStyleAlert];
    [createContactOptionsAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [createContactOptionsAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_SCAN_QR_CODE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self startReadingQRCode];
    }]];
    [createContactOptionsAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_ENTER_NAME_AND_ID style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self enterNameAndID];
    }]];
    
    [self presentViewController:createContactOptionsAlert animated:YES completion:nil];
}

- (BOOL)startReadingQRCode
{
    AVCaptureDeviceInput *input = [app getCaptureDeviceInput];
    
    if (!input) {
        return NO;
    }
    
    self.captureSession = [[AVCaptureSession alloc] init];
    [self.captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [self.captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    self.videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:self.captureSession];
    [self.videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + DEFAULT_FOOTER_HEIGHT);
    
    [self.videoPreviewLayer setFrame:frame];
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view.layer addSublayer:self.videoPreviewLayer];
    
    BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:BC_STRING_SCAN_QR_CODE view:view];

    [self presentViewController:modalViewController animated:YES completion:nil];
    
    [self.captureSession startRunning];
    
    return YES;
}

- (void)stopReadingQRCode
{
    [self.captureSession stopRunning];
    self.captureSession = nil;
    
    [self.videoPreviewLayer removeFromSuperlayer];
    
    [app closeModalWithTransition:kCATransitionFade];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects firstObject];
        
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self performSelectorOnMainThread:@selector(stopReadingQRCode) withObject:nil waitUntilDone:NO];
            
            // do something useful with results
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSString *invitation = [metadataObj stringValue];
                [app.wallet readInvitation:invitation];
            });
        }
    }
}

- (void)showInvitationAlert:(NSDictionary *)invitation identifier:(NSString *)identifier
{
    NSString *name = [invitation objectForKey:DICTIONARY_KEY_NAME];
    NSString *invitationID = [invitation objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_NEW_CONTACT message:[NSString stringWithFormat:BC_STRING_CONTACTS_SHOW_INVITATION_ALERT_MESSAGE_ARGUMENT_NAME_ARGUMENT_IDENTIFIER, name, invitationID] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_ACCEPT style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [app.wallet acceptInvitation:identifier name:name identifier:invitationID];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)enterNameAndID
{
    BCCreateContactView *createContactView = [[BCCreateContactView alloc] init];
    
    BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:BC_STRING_CREATE view:createContactView];
    
    self.createContactNavigationController = [[BCNavigationController alloc] initWithRootViewController:modalViewController title:BC_STRING_CREATE];
    
    [self presentViewController:self.createContactNavigationController animated:YES completion:nil];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [createContactView.nameField becomeFirstResponder];
    });
}

- (void)shareInvitationClicked
{
    NSString *shareLink = @"ShareLink";
    NSArray *items = @[shareLink];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc]initWithActivityItems:items applicationActivities:nil];
    
    [self.createContactNavigationController presentViewController:activityController animated:YES completion:nil];
}

#pragma mark - Wallet Callbacks

- (void)didReadInvitation:(NSDictionary *)invitation identifier:(NSString *)identifier
{
    [self showInvitationAlert:invitation identifier:identifier];
}

- (void)didAcceptInvitation:(NSDictionary *)invitation name:(NSString *)name
{
    NSString *invitationID = [invitation objectForKey:DICTIONARY_KEY_ID];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_NEW_CONTACT message:[NSString stringWithFormat:BC_STRING_CONTACTS_ACCEPTED_INVITATION_ALERT_MESSAGE_ARGUMENT_NAME_ARGUMENT_IDENTIFIER, name, invitationID] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
    
    [self reload];
}

- (void)didReadInvitationSent
{
    DLog(@"Read invitation sent success");
}

- (void)didCreateInvitation:(NSDictionary *)invitationDict
{
    NSString *identifier = [invitationDict objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED];
    NSString *sharedInfo = [invitationDict objectForKey:DICTIONARY_KEY_NAME];
    
    BCQRCodeView *qrCodeView = [[BCQRCodeView alloc] initWithFrame:self.view.frame qrHeaderText:BC_STRING_CONTACT_SCAN_INSTRUCTIONS addAddressPrefix:NO];
    qrCodeView.address = [NSString stringWithFormat:@"{name: \"%@\", invitationReceived: \"%@\"}", [sharedInfo escapeStringForJS], [identifier escapeStringForJS]];
    
    UIViewController *viewController = [UIViewController new];
    [viewController.view addSubview:qrCodeView];
    
    CGRect frame = qrCodeView.frame;
    frame.origin.y = viewController.view.frame.origin.y + DEFAULT_HEADER_HEIGHT;
    qrCodeView.frame = frame;
    
    [self.createContactNavigationController pushViewController:viewController animated:YES];
    
    [self.createContactNavigationController createTopRightButton];
    self.createContactNavigationController.topRightButton.imageEdgeInsets = UIEdgeInsetsMake(0, 44, 8, 16);
    [self.createContactNavigationController.topRightButton setImage:[UIImage imageNamed:@"icon_share"] forState:UIControlStateNormal];
    [self.createContactNavigationController.topRightButton addTarget:self action:@selector(shareInvitationClicked) forControlEvents:UIControlEventTouchUpInside];
}

- (void)didGetMessages
{
    [self.messagesViewController didGetMessages];
}

- (void)didChangeTrust
{
    [self updateContactDetail];
}

- (void)didFetchExtendedPublicKey
{
    [self updateContactDetail];
    
    [self.messagesViewController didFetchExtendedPublicKey];
}

- (void)didReadMessage:(NSString *)message
{
    [self.messagesViewController didReadMessage:message];
}

- (void)didSendMessage:(NSString *)contact
{
    [self.messagesViewController didSendMessage:contact];
}

@end

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
#import "ContactDetailViewController.h"
#import "ContactTableViewCell.h"
#import "UIView+ChangeFrameAttribute.h"

#define VIEW_NAME_NEW_CONTACT @"newContact"

const int sectionContacts = 0;

typedef enum {
    CreateContactTypeQR,
    CreateContactTypeLink
} CreateContactType;

@interface ContactsViewController () <UITableViewDelegate, UISearchBarDelegate, UITableViewDataSource, AVCaptureMetadataOutputObjectsDelegate, CreateContactDelegate, DoneButtonDelegate>

@property (nonatomic) BCNavigationController *createContactNavigationController;
@property (nonatomic) ContactDetailViewController *detailViewController;
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIView *noContactsView;
@property (nonatomic) NSDictionary *lastCreatedInvitation;
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;

@property (nonatomic) NSString *invitationFromURL;
@property (nonatomic) NSString *nameFromURL;

@property (nonatomic) NSString *invitationSentIdentifier;

@property (nonatomic) UIRefreshControl *refreshControl;

@property (nonatomic) CreateContactType contactType;

@property (nonatomic, copy) void (^onCompleteRelation)();
@property (nonatomic, copy) void (^onFailCompleteRelation)();
@property (nonatomic, copy) void (^onClickDoneButton)();

@end

@implementation ContactsViewController

#pragma mark - Lifecycle

- (id)initWithInvitation:(NSString *)identifier name:(NSString *)name
{
    if (self = [super init]) {
        self.invitationFromURL = identifier;
        self.nameFromURL = name;
    }
    return self;
}

- (id)initWithAcceptedInvitation:(NSString *)invitationSent
{
    if (self = [super init]) {
        self.invitationSentIdentifier = invitationSent;
    }
    return self;
}

- (void)showAcceptedInvitation:(NSString *)invitationSent
{
    NSArray *allContacts = [app.wallet.contacts allValues];
    for (Contact *contact in allContacts) {
        if ([contact.invitationSent isEqualToString:invitationSent]) {
            [app.wallet completeRelation:contact.identifier];
            break;
        }
    }
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.automaticallyAdjustsScrollViewInsets = NO;
    
    self.view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    navigationController.headerTitle = BC_STRING_CONTACTS;
    
    self.onClickDoneButton = nil;
    
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    if (self.invitationFromURL && self.nameFromURL) {
        [app.wallet readInvitation:[self JSDictionaryForInvitation:self.invitationFromURL name:self.nameFromURL]];
    } else if (self.invitationSentIdentifier) {
        [self showAcceptedInvitation:self.invitationSentIdentifier];
    }
    
    self.invitationFromURL = nil;
    self.nameFromURL = nil;\
    
    self.invitationSentIdentifier = nil;
    
    self.lastCreatedInvitation = nil;
    
    self.createContactNavigationController = nil;
    
    app.topViewControllerDelegate = (BCNavigationController *)self.navigationController;
}

- (void)setupTableView
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, self.view.frame.size.width, self.view.frame.size.height - DEFAULT_HEADER_HEIGHT) style:UITableViewStylePlain];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView registerClass:[ContactTableViewCell class] forCellReuseIdentifier:CELL_IDENTIFIER_CONTACT];
    
    UISearchBar *searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 0, self.tableView.frame.size.width, 44)];
    searchBar.placeholder = BC_STRING_SEARCH;
    searchBar.layer.borderColor = [COLOR_BLOCKCHAIN_BLUE CGColor];
    searchBar.layer.borderWidth = 1;
    searchBar.searchBarStyle = UISearchBarStyleProminent;
    searchBar.translucent = NO;
    searchBar.backgroundImage = [UIImage new];
    searchBar.tintAdjustmentMode = UIViewTintAdjustmentModeNormal;
    searchBar.barTintColor = COLOR_BLOCKCHAIN_BLUE;
    [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[[UISearchBar class]]] setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:
                                                                                                  [UIColor whiteColor],
                                                                                                  NSForegroundColorAttributeName,
                                                                                                  nil] 
                                                                                        forState:UIControlStateNormal];
    searchBar.delegate = self;
    self.tableView.tableHeaderView = searchBar;
    
    [self.view addSubview:self.tableView];
}

- (void)setupNoContactsView
{
    self.noContactsView = [[UIView alloc] initWithFrame:self.view.frame];
    [self.view addSubview:self.noContactsView];

    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    titleLabel.text = BC_STRING_NO_CONTACTS_YET_TITLE;
    titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_LARGE];
    titleLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [titleLabel sizeToFit];
    titleLabel.center = self.noContactsView.center;
    [self.noContactsView addSubview:titleLabel];
    
    UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectZero];
    imageView.image = [UIImage imageNamed:@"contacts_icon"];
    imageView.frame = CGRectMake(0, titleLabel.frame.origin.y - 16 - 60, 100, 60);
    imageView.center = CGPointMake(self.noContactsView.center.x, imageView.center.y);
    [self.noContactsView addSubview:imageView];
    
    UITextView *subtitleTextView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, self.noContactsView.frame.size.width - 80, 0)];
    subtitleTextView.text = BC_STRING_NO_CONTACTS_YET_SUBTITLE;
    subtitleTextView.textAlignment = NSTextAlignmentCenter;
    subtitleTextView.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
    subtitleTextView.editable = NO;
    subtitleTextView.selectable = NO;
    subtitleTextView.scrollEnabled = NO;
    subtitleTextView.textColor = COLOR_TEXT_DARK_GRAY;
    subtitleTextView.textContainerInset = UIEdgeInsetsZero;
    subtitleTextView.frame = CGRectMake(0, titleLabel.frame.origin.y + titleLabel.frame.size.height + 8, subtitleTextView.frame.size.width, subtitleTextView.contentSize.height);
    subtitleTextView.center = CGPointMake(self.noContactsView.center.x, subtitleTextView.center.y);
    subtitleTextView.backgroundColor = [UIColor clearColor];
    [subtitleTextView sizeToFit];
    [self.noContactsView addSubview:subtitleTextView];
    
    UIButton *inviteButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 240, BUTTON_HEIGHT)];
    inviteButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    [inviteButton setTitle:BC_STRING_INVITE_CONTACT forState:UIControlStateNormal];
    inviteButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
    inviteButton.titleLabel.textColor = [UIColor whiteColor];
    inviteButton.frame = CGRectMake(0, subtitleTextView.frame.origin.y + subtitleTextView.frame.size.height + 16, inviteButton.frame.size.width, inviteButton.frame.size.height);
    inviteButton.center = CGPointMake(self.noContactsView.center.x, inviteButton.center.y);
    inviteButton.layer.cornerRadius = CORNER_RADIUS_BUTTON;
    [inviteButton addTarget:self action:@selector(newContactClicked:) forControlEvents:UIControlEventTouchUpInside];

    [self.noContactsView addSubview:inviteButton];
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

- (void)reload
{
    [app.wallet getMessages];
}

- (void)updateContactDetail
{
    [self reload];
    
    NSString *contactIdentifier = self.detailViewController.contact.identifier;
    
    Contact *reloadedContact = [app.wallet.contacts objectForKey:contactIdentifier];
    
    self.detailViewController.contact = reloadedContact;
}

#pragma mark - Search Bar Delegate

- (void)searchBarTextDidBeginEditing:(UISearchBar *)searchBar
{
    searchBar.showsCancelButton = YES;
}

- (void)searchBarCancelButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
    searchBar.showsCancelButton = NO;
}

#pragma mark - Table View Delegate

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [app.wallet.contacts allValues].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ContactTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_CONTACT forIndexPath:indexPath];
    
    Contact *contact = [app.wallet.contacts allValues][indexPath.row];
    
    BOOL actionRequired = [app.wallet actionRequiredForContact:contact];
    
    [cell configureWithContact:contact actionRequired:actionRequired];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    Contact *contact = [app.wallet.contacts allValues][indexPath.row];
    
    if (self.navigationController.topViewController == self) {
        [self contactClicked:contact];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 45)];
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width, 14)];
    
    [view addSubview:label];
    
    NSString *labelString;
    
    if (section == 0) {
        labelString = BC_STRING_ADD_NEW_CONTACT;
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20 - 30, 4, 50, 40)];
        [addButton setImage:[[UIImage imageNamed:@"new"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        addButton.imageView.tintColor = COLOR_BLOCKCHAIN_BLUE;
        [addButton addTarget:self action:@selector(newContactClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:addButton];
    } else
        @throw @"Unknown Section";
    
    label.text = labelString;
    
    return view;
}

#pragma mark - Create Contact Delegate

- (void)didCreateSenderName:(NSString *)senderName contactName:(NSString *)contactName
{
    if ([self nameIsEmpty:senderName]) {
        UIAlertController *invalidNameAlert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:BC_STRING_PLEASE_ENTER_A_NAME preferredStyle:UIAlertControllerStyleAlert];
        [invalidNameAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        [self.createContactNavigationController presentViewController:invalidNameAlert animated:YES completion:nil];
    } else {
        BCCreateContactView *createContactSharingView = [[BCCreateContactView alloc] initWithContactName:contactName senderName:senderName];
        createContactSharingView.delegate = self;
        
        BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:BC_STRING_CREATE view:createContactSharingView];
        
        [self.createContactNavigationController pushViewController:modalViewController animated:YES];
    }
}

- (void)didCreateContactName:(NSString *)name
{
    if ([self nameIsEmpty:name]) {
        UIAlertController *invalidNameAlert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:BC_STRING_PLEASE_ENTER_A_NAME preferredStyle:UIAlertControllerStyleAlert];
        [invalidNameAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        
        if (self.createContactNavigationController) {
            [self.createContactNavigationController presentViewController:invalidNameAlert animated:YES completion:nil];
        } else {
            [self presentViewController:invalidNameAlert animated:YES completion:nil];
        }
    } else if ([self nameAlreadyExists:name]) {
        UIAlertController *invalidNameAlert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:BC_STRING_CONTACT_ALREADY_EXISTS preferredStyle:UIAlertControllerStyleAlert];
        [invalidNameAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        
        if (self.createContactNavigationController) {
            [self.createContactNavigationController presentViewController:invalidNameAlert animated:YES completion:nil];
        } else {
            [self presentViewController:invalidNameAlert animated:YES completion:nil];
        }
    } else {
        BCCreateContactView *createContactSenderNameView = [[BCCreateContactView alloc] initWithContactName:name senderName:nil];
        createContactSenderNameView.delegate = self;
        
        BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:BC_STRING_CREATE view:createContactSenderNameView];
        
        if (self.createContactNavigationController) {
            [self.createContactNavigationController pushViewController:modalViewController animated:YES];
        } else {
            DLog(@"Error: no create contact navigation controller");
        }
    }
}

- (void)didSelectQRCode
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING_INVITATION];
    
    if (self.lastCreatedInvitation) {
        // lastCreatedInvitation is set to nil on viewWillAppear. If at this point there is an existing invitation, that means the user clicked share via QR code after clicking shareLink. Delete old contact
        [app.wallet deleteContactAfterStoringInfo:[self.lastCreatedInvitation objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED]];
    }
    
    self.contactType = CreateContactTypeQR;
}

- (void)didSelectShareLink
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING_INVITATION];
    
    if (self.lastCreatedInvitation) {
        // lastCreatedInvitation is set to nil on viewWillAppear. If at this point there is an existing invitation, that means the user clicked shareLink twice. Delete old contact
        [app.wallet deleteContactAfterStoringInfo:[self.lastCreatedInvitation objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED]];
    }
    
    self.contactType = CreateContactTypeLink;
}

#pragma mark - Two Button View Delegate

- (void)topButtonClicked:(NSString *)senderName
{
    if ([senderName isEqualToString:VIEW_NAME_NEW_CONTACT]) {
        [self createInvitation];
    }
}

- (void)bottomButtonClicked:(NSString *)senderName
{
    if ([senderName isEqualToString:VIEW_NAME_NEW_CONTACT]) {
        [self startReadingQRCode];
    }
}

#pragma mark - Create Contact Delegate/Done Button Delegate

- (void)doneButtonClicked
{
    if (self.onClickDoneButton) {
        self.onClickDoneButton();
        self.onClickDoneButton = nil;
    }
    
    self.createContactNavigationController.onPopViewController = nil;
    self.createContactNavigationController.onViewWillDisappear = nil;
    
    [self dismissViewControllerAnimated:YES completion:^{
        self.createContactNavigationController = nil;
    }];
}

#pragma mark - Actions

- (void)contactClicked:(Contact *)contact
{
    if (contact.mdid) {
        self.detailViewController = [[ContactDetailViewController alloc] initWithContact:contact];
        [self.navigationController pushViewController:self.detailViewController animated:YES];
    } else {
        __weak ContactsViewController *weakSelf = self;
        self.onCompleteRelation = ^() {
            weakSelf.detailViewController = [[ContactDetailViewController alloc] initWithContact:contact];
            [weakSelf.navigationController pushViewController:weakSelf.detailViewController animated:YES];
        };
        self.onFailCompleteRelation = ^() {
            [weakSelf promptToResendInvitationToContact:contact];
        };
        [app.wallet completeRelation:contact.identifier];
    }
}

- (void)newContactClicked:(id)sender
{
    UIAlertController *newContactAlert = [UIAlertController alertControllerWithTitle:BC_STRING_INVITE_CONTACT message:BC_STRING_ENTER_NAME_CONTACT preferredStyle:UIAlertControllerStyleAlert];
    [newContactAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [newContactAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_NEXT style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *name = [[newContactAlert textFields] firstObject].text;
        [self promptForUserNameWithContactName:name];
    }]];
    [newContactAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        secureTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        secureTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        secureTextField.returnKeyType = UIReturnKeyNext;
    }];
    
    [self presentViewController:newContactAlert animated:YES completion:nil];
}

- (void)promptForUserNameWithContactName:(NSString *)contactName
{
    UIAlertController *userNameAlert = [UIAlertController alertControllerWithTitle:BC_STRING_INVITE_CONTACT message:[NSString stringWithFormat:BC_STRING_WHAT_NAME_DOES_ARGUMENT_KNOW_YOU_BY, contactName] preferredStyle:UIAlertControllerStyleAlert];
    [userNameAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [userNameAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_NEXT style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSString *senderName = [[userNameAlert textFields] firstObject].text;
        if ([app checkInternetConnection]) {
            [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING_INVITATION];
            [app.wallet createContactWithName:senderName ID:contactName];
        }
    }]];
    [userNameAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        secureTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        secureTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        secureTextField.returnKeyType = UIReturnKeyNext;
    }];
    
    [self presentViewController:userNameAlert animated:YES completion:nil];
}

- (void)createInvitation
{
    BCCreateContactView *createContactSharingView = [[BCCreateContactView alloc] initWithContactName:nil senderName:nil];
    createContactSharingView.delegate = self;
    
    BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:nil view:createContactSharingView];
    
    if (self.createContactNavigationController) {
        [self.createContactNavigationController pushViewController:modalViewController animated:YES];
    } else {
        self.createContactNavigationController = [self navigationControllerForNewContact:modalViewController];
        [self presentViewController:self.createContactNavigationController animated:YES completion:nil];
    }
}

- (BOOL)startReadingQRCode
{
    AVCaptureDeviceInput *input = [app getCaptureDeviceInput:self];
    
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
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height);
    
    [self.videoPreviewLayer setFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height*2/3)];
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view.layer addSublayer:self.videoPreviewLayer];
    
    UILabel *linkInstructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, self.videoPreviewLayer.frame.origin.y + self.videoPreviewLayer.frame.size.height, view.frame.size.width - 40, 60)];
    linkInstructionsLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:14];
    linkInstructionsLabel.textAlignment = NSTextAlignmentCenter;
    linkInstructionsLabel.textColor = COLOR_TEXT_DARK_GRAY;
    linkInstructionsLabel.text = BC_STRING_LINK_INVITE_INSTRUCTIONS;
    linkInstructionsLabel.numberOfLines = 0;
    [linkInstructionsLabel sizeToFit];
    linkInstructionsLabel.center = CGPointMake(view.center.x, self.videoPreviewLayer.frame.size.height + (view.frame.size.height - self.videoPreviewLayer.frame.size.height - DEFAULT_HEADER_HEIGHT)/2);
    [view addSubview:linkInstructionsLabel];
    
    BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:BC_STRING_SCAN_QR_CODE view:view];

    if (self.createContactNavigationController) {
        [self.createContactNavigationController pushViewController:modalViewController animated:YES];
    } else {
        self.createContactNavigationController = [self navigationControllerForNewContact:modalViewController];
        [self presentViewController:self.createContactNavigationController animated:YES completion:nil];
    }
    
    [self.captureSession startRunning];
    
    return YES;
}

- (void)stopReadingQRCode
{
    [self.captureSession stopRunning];
    self.captureSession = nil;
    
    [self.videoPreviewLayer removeFromSuperlayer];
    
    [self dismissViewControllerAnimated:YES completion:nil];
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

- (void)shareInvitationClicked
{
    NSString *identifier = [self.lastCreatedInvitation objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED];
    NSString *sharedInfo = [self.lastCreatedInvitation objectForKey:DICTIONARY_KEY_NAME];
    
    NSString *shareLink = [PREFIX_BLOCKCHAIN_URI stringByAppendingFormat:@"invite?id=%@&name=%@", [identifier stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]], [sharedInfo stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
    NSArray *items = @[shareLink];
    
    UIActivityViewController *activityController = [[UIActivityViewController alloc] initWithActivityItems:items applicationActivities:nil];
    
    [self presentViewController:activityController animated:YES completion:^{
        [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_SHARE_CONTACT_LINK object:nil];
    }];
}

- (void)reloadSymbols
{
    [self.detailViewController reloadSymbols];
}

- (void)promptToResendInvitationToContact:(Contact *)contact
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:BC_STRING_WAITING_FOR_ARGUMENT_TO_ACCEPT, contact.name] message:BC_STRING_RESEND_INVITE preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        self.onClickDoneButton = ^() {
            [app.wallet deleteContact:contact.identifier];
        };
        [self resendInvitationForContactName:contact.name];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleDefault handler:nil]];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_DELETE_CONTACT style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self confirmDeleteContact:contact];
    }]];
    
    [self presentViewController:alert animated:YES completion:nil];
}

- (void)confirmDeleteContact:(Contact *)contact
{
    UIAlertController *alertForDeletingContact = [UIAlertController alertControllerWithTitle:BC_STRING_DELETE_CONTACT_ALERT_TITLE message:nil preferredStyle:UIAlertControllerStyleAlert];
    [alertForDeletingContact addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [app.wallet deleteContact:contact.identifier];
    }]];
    [alertForDeletingContact addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alertForDeletingContact animated:YES completion:nil];
}

- (void)resendInvitationForContactName:(NSString *)name
{
    BCCreateContactView *createContactSenderNameView = [[BCCreateContactView alloc] initWithContactName:name senderName:nil];
    createContactSenderNameView.delegate = self;
    
    BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:BC_STRING_CREATE view:createContactSenderNameView];
    
    self.createContactNavigationController = [self navigationControllerForNewContact:modalViewController];
    [self presentViewController:self.createContactNavigationController animated:YES completion:nil];
}

- (void)contactAcceptedInvitation:(NSString *)invitationSent
{
    NSString *currentInvitationSent = [self.lastCreatedInvitation objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED];
    
    if ([invitationSent isEqualToString:currentInvitationSent]) {
        [self doneButtonClicked];
    }
}

#pragma mark - Helpers

- (NSString *)JSDictionaryForInvitation:(NSString *)identifier name:(NSString *)name;
{
    return [NSString stringWithFormat:@"{name: \"%@\", invitationReceived: \"%@\"}", [name escapeStringForJS], [identifier escapeStringForJS]];
}

- (BOOL)nameIsEmpty:(NSString *)name
{
    NSCharacterSet *inverted = [[NSCharacterSet whitespaceAndNewlineCharacterSet] invertedSet];
    NSRange range = [name rangeOfCharacterFromSet:inverted];
    return range.location == NSNotFound;
}

- (BOOL)nameAlreadyExists:(NSString *)name
{
    NSArray *allContacts = [app.wallet.contacts allValues];
    for (Contact *contact in allContacts) {
        if ([contact.name isEqualToString:name]) {
            return YES;
        }
    }
    
    return NO;
}

- (BCNavigationController *)navigationControllerForNewContact:(BCModalViewController *)modalViewController
{
    BCNavigationController *controller = [[BCNavigationController alloc] initWithRootViewController:modalViewController title:BC_STRING_ADD_NEW_CONTACT];
    
    __weak ContactsViewController *weakSelf = self;
    
    void (^checkAndDeleteContactInfo)() = ^() {
        if (weakSelf.lastCreatedInvitation) {
            NSString *contactId = [weakSelf.lastCreatedInvitation objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED];
            [app.wallet deleteContactAfterStoringInfo:contactId];
            weakSelf.lastCreatedInvitation = nil;
        }
    };
    
    controller.onPopViewController = checkAndDeleteContactInfo;
    controller.onViewWillDisappear = checkAndDeleteContactInfo;
    
    return controller;
}

#pragma mark - Wallet Callbacks

- (void)didReadInvitation:(NSDictionary *)invitation identifier:(NSString *)identifier
{
    DLog(@"Read invitation success");
    
    NSString *name = [invitation objectForKey:DICTIONARY_KEY_NAME];
    NSString *invitationID = [invitation objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED];

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [app.wallet acceptRelation:identifier name:name identifier:invitationID];
    });
}

- (void)didAcceptRelation:(NSString *)invitation name:(NSString *)name
{
    DLog(@"Accept relation/invitation success");
    [self reload];
}

- (void)didCompleteRelation
{
    DLog(@"Complete relation success");
    
    [self reload];
    
    if (self.onCompleteRelation) {
        self.onCompleteRelation();
        self.onCompleteRelation = nil;
    }
}

- (void)didFailCompleteRelation
{
    DLog(@"Complete relation failure");
    
    if (self.onFailCompleteRelation) {
        self.onFailCompleteRelation();
        self.onFailCompleteRelation = nil;
    }
}

- (void)didCreateInvitation:(NSDictionary *)invitationDict
{
    [app hideBusyView];
    
    self.lastCreatedInvitation = invitationDict;
    
    [self shareInvitationClicked];
    
    [self reload];
}

- (void)didGetMessages
{
    if (app.wallet.contacts.count > 0) {
        [self.noContactsView removeFromSuperview];
        self.noContactsView = nil;
        
        if (!self.tableView) [self setupTableView];
    } else {
        [self.tableView removeFromSuperview];
        self.tableView = nil;
        self.refreshControl = nil;
        
        [self setupNoContactsView];
    }
    
    [self.tableView reloadData];
    
    if (self.detailViewController.contact.identifier) {
        Contact *updatedContact = [app.wallet.contacts objectForKey:self.detailViewController.contact.identifier];
        
        [self.detailViewController didGetMessages:updatedContact];
    }
    
    if (self.refreshControl && self.refreshControl.isRefreshing) {
        [self.refreshControl endRefreshing];
    }
}

- (void)didFetchExtendedPublicKey
{
    [self updateContactDetail];
    
    [self.detailViewController showExtendedPublicKey];
}

- (void)didChangeContactName
{
    [self reload];
}

- (void)didDeleteContactAfterStoringInfo
{
    [self reload];
}

@end

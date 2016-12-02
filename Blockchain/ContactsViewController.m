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

const int sectionInvitations = 0;
const int sectionContacts = 1;

@interface ContactsViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic) BCNavigationController *createContactNavigationController;

@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *contacts;
@property (nonatomic) NSArray *invitations;
@end

@implementation ContactsViewController

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
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == sectionInvitations) {
        return self.invitations.count;
    } else if (section == sectionContacts) {
        return self.contacts.count;
    }
    
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_CONTACT forIndexPath:indexPath];
    cell.textLabel.text = @"";
    cell.backgroundColor = COLOR_BACKGROUND_GRAY;
    return cell;
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
        labelString = nil;
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20 - 30, 4, 50, 40)];
        [addButton setImage:[UIImage imageNamed:@"new-grey"] forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(newContactClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:addButton];
    }
    
    label.text = [labelString uppercaseString];
    
    return view;
}

- (void)newContactClicked:(id)sender
{
    UIAlertController *createContactOptionsAlert = [UIAlertController alertControllerWithTitle:BC_STRING_NEW_CONTACT message:nil preferredStyle:UIAlertControllerStyleAlert];
    [createContactOptionsAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [createContactOptionsAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_SCAN_QR_CODE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self scanQRCode];
    }]];
    [createContactOptionsAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_ENTER_NAME_AND_ID style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self enterNameAndID];
    }]];
    
    [self presentViewController:createContactOptionsAlert animated:YES completion:nil];
}

- (void)scanQRCode
{
    
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

- (void)didCreateInvitation:(NSDictionary *)invitationDict
{
    NSString *identifier = [invitationDict objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED];
    NSDictionary *sharedInfo = [invitationDict objectForKey:DICTIONARY_KEY_NAME];
    
    Invitation *invitation = [[Invitation alloc] initWithIdentifier:identifier sharedInfo:sharedInfo];
    
    BCQRCodeView *qrCodeView = [[BCQRCodeView alloc] initWithFrame:self.view.frame qrHeaderText:BC_STRING_CONTACT_SCAN_INSTRUCTIONS addAddressPrefix:NO];
    qrCodeView.address = identifier;
    
    UIViewController *viewController = [UIViewController new];
    [viewController.view addSubview:qrCodeView];
    
    CGRect frame = qrCodeView.frame;
    frame.origin.y = viewController.view.frame.origin.y + DEFAULT_HEADER_HEIGHT;
    qrCodeView.frame = frame;
    
    [self.createContactNavigationController pushViewController:viewController animated:YES];
}

@end

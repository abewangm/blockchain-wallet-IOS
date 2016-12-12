//
//  ContactMessagesViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/8/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactMessagesViewController.h"
#import "ContactDetailViewController.h"
#import "Contact.h"
#import "BCNavigationController.h"

@interface ContactMessagesViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *messages;
@property (nonatomic) UILabel *noMessagesLabel;
@property (nonatomic) ContactDetailViewController *detailViewController;
@end

@implementation ContactMessagesViewController

#pragma mark - Lifecycle

- (id)initWithContact:(Contact *)contact messages:(NSArray *)messages;
{
    if (self = [super init]) {
        _contact = contact;
        _messages = messages;
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
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CELL_IDENTIFIER_CONTACT_MESSAGE];
    
    [self.tableView reloadData];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    navigationController.headerTitle = self.contact.name;
    
    if (self.messages.count <= 0) {
        self.noMessagesLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 50, 30)];
        self.noMessagesLabel.text = BC_STRING_NO_MESSAGES;
        self.noMessagesLabel.adjustsFontSizeToFitWidth = YES;
        self.noMessagesLabel.textAlignment = NSTextAlignmentCenter;
        [self.view addSubview:self.noMessagesLabel];
        self.noMessagesLabel.center = self.view.center;
    } else {
        [self.noMessagesLabel removeFromSuperview];
    }
    
    [self setupSettings];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    [navigationController.topRightButton removeFromSuperview];
}

#pragma mark - Actions

- (void)setContact:(Contact *)contact
{
    _contact = contact;
    
    [self.tableView reloadData];
}

- (void)setupSettings
{
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    UIButton *editButton = [navigationController createTopRightButton];
    [editButton addTarget:self action:@selector(editContact) forControlEvents:UIControlEventTouchUpInside];
    [editButton setTitle:BC_STRING_EDIT forState:UIControlStateNormal];
}

- (void)editContact
{
    self.detailViewController = [[ContactDetailViewController alloc] initWithContact:self.contact];
    [self.navigationController pushViewController:self.detailViewController animated:YES];
}

#pragma mark - Table View Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_CONTACT_MESSAGE forIndexPath:indexPath];
    
    NSDictionary *messageDict = self.messages[indexPath.row];
    NSString *identifier = [messageDict objectForKey:DICTIONARY_KEY_ID];
    
    cell.textLabel.text = identifier;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSDictionary *messageDict = self.messages[indexPath.row];
    NSString *identifier = [messageDict objectForKey:DICTIONARY_KEY_ID];
    
    [app.wallet readMessage:identifier];
}

#pragma mark - Wallet callbacks

- (void)didFetchExtendedPublicKey
{
    self.detailViewController.contact = self.contact;
    [self.detailViewController showExtendedPublicKey];
}

- (void)didGetMessages;
{
    self.messages = app.wallet.messages;
    
    [self.tableView reloadData];
}

- (void)didReadMessage:(NSString *)message
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_MESSAGE message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end

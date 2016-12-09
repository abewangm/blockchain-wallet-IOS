//
//  ContactMessagesViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/8/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactMessagesViewController.h"
#import "Contact.h"

@interface ContactMessagesViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *messages;
@end

@implementation ContactMessagesViewController

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
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:CELL_IDENTIFIER_CONTACT_MESSAGE];
    
    [self.tableView reloadData];
}

- (void)setContact:(Contact *)contact
{
    _contact = contact;
    
    [self.tableView reloadData];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_CONTACT_MESSAGE forIndexPath:indexPath];
    cell.textLabel.text = BC_STRING_OK;
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.messages.count;
}

@end

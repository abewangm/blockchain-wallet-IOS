//
//  TransactionRecipientsViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 9/12/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionRecipientsViewController.h"
#import "ReceiveTableCell.h"
#import "NSNumberFormatter+Currencies.h"

@interface TransactionRecipientsViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) NSArray *recipients;
@property (nonatomic) UITableView *tableView;
@end

@implementation TransactionRecipientsViewController

- (id)initWithRecipients:(NSArray *)recipients
{
    self = [super init];
    if (self) {
        self.recipients = recipients;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.frame style:UITableViewStyleGrouped];
    self.tableView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.recipients.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ReceiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_TRANSACTION_RECIPIENT];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
        cell.backgroundColor = COLOR_BACKGROUND_GRAY;
        
        cell.labelLabel.frame = CGRectMake(20, 11, 155, 21);
        cell.balanceLabel.frame = CGRectMake(247, 11, 90, 21);
        UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 217, cell.frame.size.height-(cell.frame.size.height-cell.balanceLabel.frame.origin.y-cell.balanceLabel.frame.size.height), 0);
        cell.balanceButton.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, contentInsets);
        
        cell.watchLabel.hidden = NO;
        cell.watchLabel.text = BC_STRING_DEFAULT;
        cell.watchLabel.textColor = [UIColor grayColor];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    
    NSDictionary *recipient = self.recipients[indexPath.row];
    
    NSString *label = recipient[DICTIONARY_KEY_LABEL];
    uint64_t amount = [recipient[DICTIONARY_KEY_AMOUNT] longLongValue];
    cell.labelLabel.text = label && label.length > 0 ? label : recipient[DICTIONARY_KEY_ADDRESS];
    cell.balanceLabel.text = [NSString stringWithFormat:@"%@", [NSNumberFormatter formatMoneyWithLocalSymbol:amount]];
    cell.addressLabel.text = recipient[DICTIONARY_KEY_ADDRESS];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.0f;
}

@end

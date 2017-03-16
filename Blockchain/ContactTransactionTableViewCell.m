//
//  ContactTransactionTableViewCell.m
//  Blockchain
//
//  Created by kevinwu on 1/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactTransactionTableViewCell.h"
#import "NSNumberFormatter+Currencies.h"
#import "NSDateFormatter+TimeAgoString.h"
#import "TransactionDetailViewController.h"
#import "TransactionDetailNavigationController.h"
#import "Transaction.h"
#import "RootService.h"

@interface ContactTransactionTableViewCell()
@property (nonatomic) BOOL isSetup;
@end
@implementation ContactTransactionTableViewCell

- (id)initWithTransaction:(ContactTransaction *)transaction style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        self.transaction = transaction;
    }
    return self;
}

- (void)configureWithTransaction:(ContactTransaction *)transaction contactName:(NSString *)name
{
    self.transaction = transaction;
    
    if (self.isSetup) {
        [self reloadTextAndImage:transaction contactName:name];
        return;
    }
    
    self.actionImageView = [[UIImageView alloc] init];
    [self.contentView addSubview:self.actionImageView];
    self.actionImageView.image = [UIImage imageNamed:@"backup_red_circle"];
    
    self.accessoryType = UITableViewCellAccessoryNone;
    
    self.mainLabel = [[UILabel alloc] init];
    self.mainLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:12];
    self.mainLabel.textColor = [UIColor grayColor];
    self.mainLabel.numberOfLines = 3;
    [self.contentView addSubview:self.mainLabel];
    
    self.separator = [[UIView alloc] init];
    self.separator.backgroundColor = [UIColor lightGrayColor];
    [self.contentView addSubview:self.separator];
    
    [self reloadTextAndImage:transaction contactName:name];
    
    self.isSetup = YES;
}

- (void)reloadTextAndImage:(ContactTransaction *)transaction contactName:(NSString *)name
{
    NSString *amount = [NSNumberFormatter formatMoney:transaction.intendedAmount localCurrency:NO];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:transaction.lastUpdated];
    NSString *dateString = [NSDateFormatter timeAgoStringFromDate:date];
    
    if (transaction.transactionState == ContactTransactionStateSendWaitingForQR) {
        self.mainLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@", [NSString stringWithFormat:BC_STRING_SENDING_ARGUMENT_TO_NAME_ARGUMENT, amount, name], [NSString stringWithFormat:BC_STRING_WAITING_FOR_ARGUMENT_TO_ACCEPT, name], dateString];
        self.actionImageView.hidden = YES;
    } else if (transaction.transactionState == ContactTransactionStateReceiveAcceptOrDenyPayment) {
        self.mainLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@", [NSString stringWithFormat:BC_STRING_RECEIVING_ARGUMENT_FROM_NAME_ARGUMENT, amount, name],BC_STRING_ACCEPT_OR_DENY, dateString];
        self.actionImageView.hidden = NO;
    } else if (transaction.transactionState == ContactTransactionStateSendReadyToSend) {
        self.mainLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@", [NSString stringWithFormat:BC_STRING_SENDING_ARGUMENT_TO_NAME_ARGUMENT, amount, name],BC_STRING_READY_TO_SEND, dateString];
        self.actionImageView.hidden = NO;
    } else if (transaction.transactionState == ContactTransactionStateReceiveWaitingForPayment) {
        self.mainLabel.text = [NSString stringWithFormat:@"%@\n%@\n%@", [NSString stringWithFormat:BC_STRING_REQUESTED_ARGUMENT_FROM_NAME_ARGUMENT, amount, name], BC_STRING_WAITING_FOR_PAYMENT, dateString];
        self.actionImageView.hidden = YES;
    } else if (transaction.transactionState == ContactTransactionStateCompletedSend) {
        self.mainLabel.text = [NSString stringWithFormat:@"%@\n%@", [NSString stringWithFormat:BC_STRING_SENT_ARGUMENT_TO_ARGUMENT, amount, name], dateString];
        self.actionImageView.hidden = YES;
    } else if (transaction.transactionState == ContactTransactionStateCompletedReceive) {
        self.mainLabel.text = [NSString stringWithFormat:@"%@\n%@", [NSString stringWithFormat:BC_STRING_RECEIVED_ARGUMENT_FROM_ARGUMENT, amount, name], dateString];
        self.actionImageView.hidden = YES;
    } else {
        self.mainLabel.text = [NSString stringWithFormat:@"state: %@ role: %@", transaction.state, transaction.role];
        self.actionImageView.hidden = NO;
    }

    self.accessoryType = UITableViewCellAccessoryNone;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.actionImageView.frame = CGRectMake(15, (self.frame.size.height - 13)/2, 13, 13);
    CGFloat mainLabelOriginX = self.actionImageView.frame.origin.x + self.actionImageView.frame.size.width + 8;
    self.mainLabel.frame = CGRectMake(mainLabelOriginX, (self.frame.size.height - 60)/2, self.frame.size.width - mainLabelOriginX - 28, 60);
    self.separator.frame = CGRectMake(0, 0, self.frame.size.width, 0.5);
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.accessoryType = UITableViewCellAccessoryNone;
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    self.actionImageView.hidden = YES;
}

- (void)transactionClicked:(UIButton *)button indexPath:(NSIndexPath *)indexPath
{
    TransactionDetailViewController *detailViewController = [TransactionDetailViewController new];
    detailViewController.transaction = self.transaction;
    
    TransactionDetailNavigationController *navigationController = [[TransactionDetailNavigationController alloc] initWithRootViewController:detailViewController];
    
    detailViewController.busyViewDelegate = navigationController;
    navigationController.onDismiss = ^() {
        app.transactionsViewController.detailViewController = nil;
    };
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    app.transactionsViewController.detailViewController = detailViewController;
    [app.tabViewController presentViewController:navigationController animated:YES completion:nil];
}

@end

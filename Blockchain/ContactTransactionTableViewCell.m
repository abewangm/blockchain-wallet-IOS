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

- (void)configureWithTransaction:(ContactTransaction *)transaction contactName:(NSString *)name
{
    self.transaction = transaction;
    
    if (self.isSetup) {
        [self reloadTextAndImage:transaction contactName:name];
        return;
    }
    
    self.accessoryType = UITableViewCellAccessoryNone;
    
    self.statusLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:12];
    self.statusLabel.textColor = [UIColor grayColor];
    self.statusLabel.adjustsFontSizeToFitWidth = YES;
    
    [self reloadTextAndImage:transaction contactName:name];
    
    self.isSetup = YES;
}

- (void)reloadTextAndImage:(ContactTransaction *)transaction contactName:(NSString *)name
{
    NSString *amount = [NSNumberFormatter formatMoney:transaction.intendedAmount];
    [self.amountButton setTitle:amount forState:UIControlStateNormal];
    
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:transaction.lastUpdated];
    NSString *dateString = [NSDateFormatter timeAgoStringFromDate:date];
    self.lastUpdatedLabel.text = dateString;
    
    NSString *convertedNote = [transaction.note stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString *toFromLabelTextSuffix = convertedNote.length > 0 ? [NSString stringWithFormat:@"%@ (%@)", name, transaction.note] : name;

    if (transaction.transactionState == ContactTransactionStateSendWaitingForQR) {
        self.statusLabel.text = BC_STRING_CONTACT_TRANSACTION_STATE_WAITING_FOR_QR;
        self.statusLabel.textColor = COLOR_TRANSACTION_SENT;
        self.amountButton.backgroundColor = COLOR_TRANSACTION_SENT;
        self.toFromLabel.text = [NSString stringWithFormat:@"%@ %@", BC_STRING_TO, toFromLabelTextSuffix];
        [self showLighterColors];
    } else if (transaction.transactionState == ContactTransactionStateReceiveAcceptOrDenyPayment) {
        self.statusLabel.text = BC_STRING_CONTACT_TRANSACTION_STATE_ACCEPT_OR_DENY_PAYMENT;
        self.statusLabel.textColor = COLOR_TRANSACTION_RECEIVED;
        self.amountButton.backgroundColor = COLOR_TRANSACTION_RECEIVED;
        self.toFromLabel.text = [NSString stringWithFormat:@"%@ %@", BC_STRING_FROM, toFromLabelTextSuffix];
        [self showNormalColors];
    } else if (transaction.transactionState == ContactTransactionStateSendReadyToSend) {
        self.statusLabel.text = BC_STRING_CONTACT_TRANSACTION_STATE_READY_TO_SEND;
        self.statusLabel.textColor = COLOR_TRANSACTION_SENT;
        self.amountButton.backgroundColor = COLOR_TRANSACTION_SENT;
        self.toFromLabel.text = [NSString stringWithFormat:@"%@ %@", BC_STRING_TO, toFromLabelTextSuffix];
        [self showNormalColors];
    } else if (transaction.transactionState == ContactTransactionStateReceiveWaitingForPayment) {
        self.statusLabel.text = [transaction.role isEqualToString:TRANSACTION_ROLE_PR_INITIATOR] ?  BC_STRING_CONTACT_TRANSACTION_STATE_WAITING_FOR_PAYMENT_PAYMENT_REQUEST : BC_STRING_CONTACT_TRANSACTION_STATE_WAITING_FOR_PAYMENT_REQUEST_PAYMENT_REQUEST;
        self.statusLabel.textColor = COLOR_TRANSACTION_RECEIVED;
        self.amountButton.backgroundColor = COLOR_TRANSACTION_RECEIVED;
        self.toFromLabel.text = [NSString stringWithFormat:@"%@ %@", BC_STRING_FROM, toFromLabelTextSuffix];
        [self showLighterColors];
    } else {
        self.statusLabel.text = [NSString stringWithFormat:@"state: %@ role: %@", transaction.state, transaction.role];
        [self showNormalColors];
    }

    self.accessoryType = UITableViewCellAccessoryNone;
}

- (void)showLighterColors
{
    self.amountButton.alpha = 0.5;
    self.statusLabel.alpha = 0.5;
}

- (void)showNormalColors
{
    self.amountButton.alpha = 1;
    self.statusLabel.alpha = 1;
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

- (IBAction)amountButtonClicked:(UIButton *)sender
{
    [app toggleSymbol];
}

@end

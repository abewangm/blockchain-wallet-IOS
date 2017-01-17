//
//  ContactTransactionTableViewCell.m
//  Blockchain
//
//  Created by kevinwu on 1/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactTransactionTableViewCell.h"
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

- (void)configureWithTransaction:(ContactTransaction *)transaction
{
    if (self.isSetup) {
        [self reloadTextAndImage:transaction];
        return;
    }
    
    self.actionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, (self.frame.size.height - 26)/2, 26, 26)];
    [self.contentView addSubview:self.actionImageView];
    self.actionImageView.image = [UIImage imageNamed:@"icon_support"];
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    CGFloat mainLabelOriginX = self.actionImageView.frame.origin.x + self.actionImageView.frame.size.width + 8;
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainLabelOriginX, (self.frame.size.height - 30)/2, self.frame.size.width - mainLabelOriginX - 28, 30)];
    [self.contentView addSubview:self.mainLabel];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    
    [self reloadTextAndImage:transaction];
    
    self.isSetup = YES;
}

- (void)reloadTextAndImage:(ContactTransaction *)transaction
{
    if (transaction.transactionState == ContactTransactionStateSendWaitingForQR) {
        self.mainLabel.text = @"Waiting for address";
        self.actionImageView.hidden = YES;
    } else if (transaction.transactionState == ContactTransactionStateReceiveAcceptOrDenyPayment) {
        self.mainLabel.text = [NSString stringWithFormat:@"Receiving %lld - Accept/Deny", transaction.intendedAmount];
        self.actionImageView.hidden = NO;
    } else if (transaction.transactionState == ContactTransactionStateSendReadyToSend) {
        self.mainLabel.text = [NSString stringWithFormat:@"Sending %lld - Ready to send", transaction.intendedAmount];
        self.actionImageView.hidden = NO;
    } else {
        self.mainLabel.text = [NSString stringWithFormat:@"state: %@ role: %@", transaction.state, transaction.role];
        self.actionImageView.hidden = NO;
    }

    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.accessoryType = UITableViewCellAccessoryNone;
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    self.actionImageView.hidden = YES;
}

@end

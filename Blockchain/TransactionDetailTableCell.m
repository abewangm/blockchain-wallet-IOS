//
//  TransactionDetailTableCell.m
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailTableCell.h"
#import "NSNumberFormatter+Currencies.h"

@implementation TransactionDetailTableCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    
    [self.textView removeFromSuperview];
    [self.topLabel removeFromSuperview];
    [self.bottomLabel removeFromSuperview];
    [self.topAccessoryLabel removeFromSuperview];
    [self.bottomAccessoryLabel removeFromSuperview];
    [self.fiatValueWhenSentLabel removeFromSuperview];
    [self.transactionFeeLabel removeFromSuperview];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier]) {
    }
    return self;
}

- (void)configureDescriptionCell:(Transaction *)transaction
{
    self.textLabel.text = BC_STRING_DESCRIPTION;
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(self.frame.size.width/2, self.contentView.layoutMargins.top, self.frame.size.width/2 - self.contentView.layoutMargins.right, self.frame.size.height - self.contentView.layoutMargins.top - self.contentView.layoutMargins.bottom)];
    self.textView.scrollEnabled = NO;
    self.textView.textAlignment = NSTextAlignmentRight;
    [self.textView setFont:[UIFont systemFontOfSize:15]];
    
    self.defaultTextViewHeight = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)].height;
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width, self.defaultTextViewHeight);
    
    self.textView.delegate = self;
    [self addSubview:self.textView];
    
    if (transaction.note.length > 0) {
        self.textView.text = transaction.note;
    } else {
        [self addPlaceholderLabel];
    }
}

- (void)configureValueCell:(Transaction *)transaction
{
    // Label for Sent, Transferred, or Received
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.frame.size.height/2 - 30 - 4, self.frame.size.width/3, 30)];
    self.topLabel.adjustsFontSizeToFitWidth = YES;
    
    if ([transaction.txType isEqualToString:TX_TYPE_TRANSFER]) {
        self.topLabel.text = [BC_STRING_TRANSFERRED uppercaseString];
        self.topLabel.textColor = COLOR_TRANSACTION_TRANSFERRED;
    } else if ([transaction.txType isEqualToString:TX_TYPE_RECEIVED]) {
        self.topLabel.text = [BC_STRING_RECEIVED uppercaseString];
        self.topLabel.textColor = COLOR_TRANSACTION_RECEIVED;
    } else {
        self.topLabel.text = [BC_STRING_SENT uppercaseString];
        self.topLabel.textColor = COLOR_TRANSACTION_SENT;
    }
    [self addSubview:self.topLabel];
    
    // Amount label
    self.topAccessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/3, self.topLabel.frame.origin.y, self.frame.size.width*2/3 - self.contentView.layoutMargins.right, 30)];
    self.topAccessoryLabel.textAlignment = NSTextAlignmentRight;
    self.topAccessoryLabel.adjustsFontSizeToFitWidth = YES;
    self.topAccessoryLabel.text = [NSNumberFormatter formatMoney:ABS(transaction.amount) localCurrency:NO];
    
    self.topAccessoryLabel.textColor = self.topLabel.textColor;
    [self addSubview:self.topAccessoryLabel];
    
    // Transaction fee label
    self.transactionFeeLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/3, self.frame.size.height - self.contentView.layoutMargins.bottom - 21, self.frame.size.width*2/3 - self.contentView.layoutMargins.right, 21)];
    self.transactionFeeLabel.font = [UIFont systemFontOfSize:12];
    self.transactionFeeLabel.text = [NSString stringWithFormat:BC_STRING_TRANSACTION_FEE_ARGUMENT, [NSNumberFormatter formatMoney:ABS(transaction.fee) localCurrency:NO]];
    self.transactionFeeLabel.adjustsFontSizeToFitWidth = YES;
    self.transactionFeeLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.transactionFeeLabel];
    
    // Value when sent label
    self.fiatValueWhenSentLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/3, self.frame.size.height - self.transactionFeeLabel.frame.size.height - 21 - 8, self.frame.size.width*2/3 - self.contentView.layoutMargins.right, 21)];
    self.fiatValueWhenSentLabel.font = [UIFont systemFontOfSize:12];
    self.fiatValueWhenSentLabel.text = [NSString stringWithFormat:BC_STRING_VALUE_WHEN_SENT_ARGUMENT, [NSNumberFormatter formatMoney:ABS(transaction.amount) localCurrency:YES]];
    self.fiatValueWhenSentLabel.adjustsFontSizeToFitWidth = YES;
    self.fiatValueWhenSentLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.fiatValueWhenSentLabel];
}

- (void)configureToFromCell:(Transaction *)transaction
{
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.frame.size.height/2 - 30 - 4, 70, 30)];
    self.topLabel.text = BC_STRING_TO;
    [self addSubview:self.topLabel];

    self.bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.frame.size.height/2 + 4, self.topLabel.frame.size.width, 30)];
    self.bottomLabel.text = BC_STRING_FROM;
    [self addSubview:self.bottomLabel];
    
    self.topAccessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width/3, self.topLabel.frame.origin.y, self.frame.size.width*2/3 - self.contentView.layoutMargins.right, 30)];
    self.topAccessoryLabel.textAlignment = NSTextAlignmentRight;
    self.topAccessoryLabel.adjustsFontSizeToFitWidth = YES;
    self.topAccessoryLabel.text = transaction.to.count > 1 ? [NSString stringWithFormat:BC_STRING_ARGUMENT_RECIPIENTS, transaction.to.count] : [transaction.to.firstObject objectForKey:DICTIONARY_KEY_ADDRESS];
    [self addSubview:self.topAccessoryLabel];

    self.bottomAccessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.topAccessoryLabel.frame.origin.x, self.bottomLabel.frame.origin.y, self.topAccessoryLabel.frame.size.width, 30)];
    self.bottomAccessoryLabel.textAlignment = NSTextAlignmentRight;
    self.bottomAccessoryLabel.adjustsFontSizeToFitWidth = YES;
    self.bottomAccessoryLabel.text = transaction.from.label;
    [self addSubview:self.bottomAccessoryLabel];
}

- (void)configureDateCell:(Transaction *)transaction
{
    self.textLabel.text = BC_STRING_DATE;
}

- (void)configureStatusCell:(Transaction *)transaction
{
    self.textLabel.text = BC_STRING_STATUS;
    if (transaction.confirmations >= kConfirmationThreshold) {
        self.detailTextLabel.text = BC_STRING_CONFIRMED;
    } else {
        self.detailTextLabel.text = [NSString stringWithFormat:BC_STRING_PENDING_ARGUMENT_CONFIRMATIONS, transaction.confirmations];
    }
}

- (void)addPlaceholderLabel
{
    self.textViewPlaceholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x - 8, self.textView.frame.origin.y, self.textView.frame.size.width, self.defaultTextViewHeight)];
    self.textViewPlaceholderLabel.textAlignment = NSTextAlignmentRight;
    self.textViewPlaceholderLabel.font = [self.textView.font fontWithSize:self.textView.font.pointSize];
    self.textViewPlaceholderLabel.textColor = [UIColor lightGrayColor];
    self.textViewPlaceholderLabel.text = BC_STRING_TRANSACTION_DESCRIPTION_PLACEHOLDER;
    self.textViewPlaceholderLabel.adjustsFontSizeToFitWidth = YES;
    [self addSubview:self.textViewPlaceholderLabel];
}

#pragma mark - TextView delegate

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        [self addPlaceholderLabel];
    } else {
        [self.textViewPlaceholderLabel removeFromSuperview];
    }
    
    [self.detailViewDelegate textViewDidChange:textView];
}

@end

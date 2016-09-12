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
    [self.bottomAccessoryLabel removeFromSuperview];
    [self.fiatValueWhenSentLabel removeFromSuperview];
    [self.transactionFeeLabel removeFromSuperview];
    [self.textViewPlaceholderLabel removeFromSuperview];
    
    [self.amountButton removeFromSuperview];
    [self.topAccessoryButton removeFromSuperview];
    [self.editButton removeFromSuperview];
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
    self.textLabel.textColor = [UIColor lightGrayColor];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(self.frame.size.width/2, self.contentView.layoutMargins.top, self.frame.size.width/2 - self.contentView.layoutMargins.right, self.frame.size.height - self.contentView.layoutMargins.top - self.contentView.layoutMargins.bottom)];
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textView.scrollEnabled = NO;
    self.textView.textAlignment = NSTextAlignmentRight;
    [self.textView setFont:[UIFont systemFontOfSize:15]];
    
    self.defaultTextViewHeight = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)].height;
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width - self.defaultTextViewHeight, self.defaultTextViewHeight);
    
    self.textView.delegate = self;
    [self addSubview:self.textView];
    self.textView.userInteractionEnabled = NO;
    
    [self addEditButton];
    
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
    self.topLabel.textColor = [UIColor lightGrayColor];
    
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
    
    CGFloat XPositionForAccessoryViews = self.contentView.layoutMargins.left + self.topLabel.frame.size.width;
    
    // Amount button
    self.amountButton = [[UIButton alloc] initWithFrame:CGRectMake(XPositionForAccessoryViews, self.topLabel.frame.origin.y, self.frame.size.width - XPositionForAccessoryViews - self.contentView.layoutMargins.right, 30)];
    self.amountButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    self.amountButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.amountButton setTitle:[NSNumberFormatter formatMoneyWithLocalSymbol:ABS(transaction.amount)] forState:UIControlStateNormal];
    [self.amountButton addTarget:self action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
    
    [self.amountButton setTitleColor:self.topLabel.textColor forState:UIControlStateNormal];
    [self addSubview:self.amountButton];
    
    // Transaction fee label
    self.transactionFeeLabel = [[UILabel alloc] initWithFrame:CGRectMake(XPositionForAccessoryViews, self.frame.size.height - self.contentView.layoutMargins.bottom - 21, self.frame.size.width - XPositionForAccessoryViews - self.contentView.layoutMargins.right, 21)];
    self.transactionFeeLabel.font = [UIFont systemFontOfSize:12];
    self.transactionFeeLabel.textColor = [UIColor lightGrayColor];
    self.transactionFeeLabel.text = [NSString stringWithFormat:BC_STRING_TRANSACTION_FEE_ARGUMENT, [NSNumberFormatter formatMoneyWithLocalSymbol:ABS(transaction.fee)]];
    self.transactionFeeLabel.adjustsFontSizeToFitWidth = YES;
    self.transactionFeeLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.transactionFeeLabel];
    
    // Value when sent label
    self.fiatValueWhenSentLabel = [[UILabel alloc] initWithFrame:CGRectMake(XPositionForAccessoryViews, self.frame.size.height - self.transactionFeeLabel.frame.size.height - 21 - 8, self.frame.size.width - XPositionForAccessoryViews - self.contentView.layoutMargins.right, 21)];
    self.fiatValueWhenSentLabel.font = [UIFont systemFontOfSize:12];
    
    if (transaction.fiatAmountAtTime) {
        self.fiatValueWhenSentLabel.attributedText = nil;
        self.fiatValueWhenSentLabel.textColor = [UIColor lightGrayColor];
        self.fiatValueWhenSentLabel.text = [NSString stringWithFormat:BC_STRING_VALUE_WHEN_SENT_ARGUMENT, [NSNumberFormatter appendStringToFiatSymbol:transaction.fiatAmountAtTime]];
    } else {
        self.fiatValueWhenSentLabel.text = nil;
        NSMutableAttributedString *attributedString = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:BC_STRING_VALUE_WHEN_SENT_ARGUMENT, @".........."]];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor lightGrayColor] range:NSMakeRange(0,attributedString.length - 10)];
        [attributedString addAttribute:NSForegroundColorAttributeName value:[UIColor clearColor] range:NSMakeRange(attributedString.length - 10, 10)];
        self.fiatValueWhenSentLabel.attributedText = attributedString;
    }
    
    self.fiatValueWhenSentLabel.adjustsFontSizeToFitWidth = YES;
    self.fiatValueWhenSentLabel.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.fiatValueWhenSentLabel];
}

- (void)configureToFromCell:(Transaction *)transaction
{
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.frame.size.height/2 - 30 - 4, 70, 30)];
    self.topLabel.text = BC_STRING_TO;
    self.topLabel.textColor = [UIColor lightGrayColor];
    [self addSubview:self.topLabel];

    self.bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.topLabel.frame.origin.x, self.frame.size.height/2 + 4, self.topLabel.frame.size.width, 30)];
    self.bottomLabel.text = BC_STRING_FROM;
    self.bottomLabel.textColor = [UIColor lightGrayColor];
    [self addSubview:self.bottomLabel];
    
    self.topAccessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/3, self.topLabel.frame.origin.y, self.frame.size.width*2/3 - self.contentView.layoutMargins.right, 30)];
    self.topAccessoryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    self.topAccessoryButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    NSString *buttonTitle;
    UIColor *titleColor;
    
    if (transaction.to.count > 1) {
        buttonTitle = [NSString stringWithFormat:BC_STRING_ARGUMENT_RECIPIENTS, transaction.to.count];
        titleColor = COLOR_BUTTON_BLUE;
        [self.topAccessoryButton addTarget:self action:@selector(showRecipients) forControlEvents:UIControlEventTouchUpInside];
    } else {
        titleColor = [UIColor blackColor];
        buttonTitle = [transaction.to.firstObject objectForKey:DICTIONARY_KEY_ADDRESS];
    }
    
    [self.topAccessoryButton setTitleColor:titleColor forState:UIControlStateNormal];
    [self.topAccessoryButton setTitle:buttonTitle forState:UIControlStateNormal];
    
    [self addSubview:self.topAccessoryButton];

    self.bottomAccessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.topAccessoryButton.frame.origin.x, self.bottomLabel.frame.origin.y, self.topAccessoryButton.frame.size.width, 30)];
    self.bottomAccessoryLabel.textAlignment = NSTextAlignmentRight;
    self.bottomAccessoryLabel.adjustsFontSizeToFitWidth = YES;
    self.bottomAccessoryLabel.text = transaction.from.label;
    [self addSubview:self.bottomAccessoryLabel];
}

- (void)configureDateCell:(Transaction *)transaction
{
    self.textLabel.text = BC_STRING_DATE;
    self.textLabel.textColor = [UIColor lightGrayColor];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setAMSymbol:@"am"];
    [dateFormatter setPMSymbol:@"pm"];
    [dateFormatter setDateFormat:@"MMMM dd, yyyy @ h:mmaa"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:transaction.time];
    NSString *dateString = [dateFormatter stringFromDate:date];
    self.detailTextLabel.text = dateString;
    self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)configureStatusCell:(Transaction *)transaction
{
    self.textLabel.text = BC_STRING_STATUS;
    self.textLabel.textColor = [UIColor lightGrayColor];

    self.topAccessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(self.frame.size.width/2, 0, self.frame.size.width/2 - self.contentView.layoutMargins.right, self.frame.size.height)];
    NSString *buttonTitle = transaction.confirmations >= kConfirmationThreshold ? BC_STRING_CONFIRMED : [NSString stringWithFormat:BC_STRING_PENDING_ARGUMENT_CONFIRMATIONS, transaction.confirmations];

    self.topAccessoryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.topAccessoryButton addTarget:self action:@selector(showWebviewDetail) forControlEvents:UIControlEventTouchUpInside];
    [self.topAccessoryButton setTitle:buttonTitle forState:UIControlStateNormal];
    [self.topAccessoryButton setTitleColor:COLOR_BUTTON_BLUE forState:UIControlStateNormal];
    [self addSubview:self.topAccessoryButton];
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

- (void)addEditButton
{
    self.editButton = [[UIButton alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x + self.textView.frame.size.width, self.textView.frame.origin.y, self.defaultTextViewHeight, self.defaultTextViewHeight)];
    [self.editButton setImage:[UIImage imageNamed:@"pencil"] forState:UIControlStateNormal];
    [self.editButton setImage:[self.editButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.editButton.imageView setTintColor:[UIColor lightGrayColor]];
    self.editButton.imageEdgeInsets = UIEdgeInsetsMake(8, 8, 8, 8);
    [self.editButton addTarget:self action:@selector(editDescription) forControlEvents:UIControlEventTouchUpInside];
    [self addSubview:self.editButton];
}

- (void)editDescription
{
    [self.editButton removeFromSuperview];
    self.textView.userInteractionEnabled = YES;
    [self.textView becomeFirstResponder];
}

- (void)toggleSymbol
{
    [self.detailViewDelegate toggleSymbol];
}

- (void)showWebviewDetail
{
    [self.detailViewDelegate showWebviewDetail];
}

- (void)showRecipients
{
    [self.detailViewDelegate showRecipients];
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

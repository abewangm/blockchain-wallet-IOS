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
    [self.mainLabel removeFromSuperview];
    [self.accessoryLabel removeFromSuperview];
    [self.fiatValueWhenSentLabel removeFromSuperview];
    [self.transactionFeeLabel removeFromSuperview];
    [self.textViewPlaceholderLabel removeFromSuperview];
    
    [self.amountButton removeFromSuperview];
    [self.accessoryButton removeFromSuperview];
    [self.editButton removeFromSuperview];
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)configureDescriptionCell:(Transaction *)transaction
{
    self.textLabel.text = BC_STRING_DESCRIPTION;
    self.textLabel.adjustsFontSizeToFitWidth = YES;
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
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.frame.size.height/2 - 30 - 4, self.frame.size.width/3, 30)];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.textColor = [UIColor lightGrayColor];
    
    if ([transaction.txType isEqualToString:TX_TYPE_TRANSFER]) {
        self.mainLabel.text = [BC_STRING_TRANSFERRED uppercaseString];
        self.mainLabel.textColor = COLOR_TRANSACTION_TRANSFERRED;
    } else if ([transaction.txType isEqualToString:TX_TYPE_RECEIVED]) {
        self.mainLabel.text = [BC_STRING_RECEIVED uppercaseString];
        self.mainLabel.textColor = COLOR_TRANSACTION_RECEIVED;
    } else {
        self.mainLabel.text = [BC_STRING_SENT uppercaseString];
        self.mainLabel.textColor = COLOR_TRANSACTION_SENT;
    }
    [self addSubview:self.mainLabel];
    
    CGFloat XPositionForAccessoryViews = self.contentView.layoutMargins.left + self.mainLabel.frame.size.width;
    
    // Amount button
    self.amountButton = [[UIButton alloc] initWithFrame:CGRectMake(XPositionForAccessoryViews, self.mainLabel.frame.origin.y, self.frame.size.width - XPositionForAccessoryViews - self.contentView.layoutMargins.right, 30)];
    self.amountButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    self.amountButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.amountButton setTitle:[NSNumberFormatter formatMoneyWithLocalSymbol:ABS(transaction.amount)] forState:UIControlStateNormal];
    [self.amountButton addTarget:self action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
    
    [self.amountButton setTitleColor:self.mainLabel.textColor forState:UIControlStateNormal];
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

- (void)configureToCell:(Transaction *)transaction
{
    if (transaction.to.count > 1) {
        self.textLabel.text = BC_STRING_TO;
        self.textLabel.adjustsFontSizeToFitWidth = YES;
        self.textLabel.textColor = [UIColor lightGrayColor];
        
        self.detailTextLabel.text = [NSString stringWithFormat:BC_STRING_ARGUMENT_RECIPIENTS, transaction.to.count];
        self.detailTextLabel.textColor = [UIColor lightGrayColor];
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, 0, 70, self.frame.size.height)];
        self.mainLabel.adjustsFontSizeToFitWidth = YES;
        self.mainLabel.text = BC_STRING_TO;
        self.mainLabel.textColor = [UIColor lightGrayColor];
        [self addSubview:self.mainLabel];
        
        CGFloat accessoryLabelXPosition = self.mainLabel.frame.origin.x + self.mainLabel.frame.size.width + 8;
        self.accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(accessoryLabelXPosition, 0, self.frame.size.width - self.contentView.layoutMargins.right - accessoryLabelXPosition, self.frame.size.height)];
        self.accessoryLabel.textAlignment = NSTextAlignmentRight;
        self.accessoryLabel.text = [transaction.to.firstObject objectForKey:DICTIONARY_KEY_LABEL];
        self.accessoryLabel.adjustsFontSizeToFitWidth = YES;
        self.accessoryLabel.textColor = [UIColor blackColor];
        [self addSubview:self.accessoryLabel];
        self.accessoryType = UITableViewCellAccessoryNone;
    }
}

- (void)configureFromCell:(Transaction *)transaction
{
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, 0, 70, 20.5)];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.text = BC_STRING_FROM;
    self.mainLabel.textColor = [UIColor lightGrayColor];
    [self addSubview:self.mainLabel];
    
    CGFloat accessoryLabelXPosition = self.mainLabel.frame.origin.x + self.mainLabel.frame.size.width + 8;
    self.accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(accessoryLabelXPosition, 0, self.frame.size.width - self.contentView.layoutMargins.right - accessoryLabelXPosition, 20.5)];
    self.accessoryLabel.textAlignment = NSTextAlignmentRight;
    self.accessoryLabel.adjustsFontSizeToFitWidth = YES;
    self.accessoryLabel.text = transaction.from.label;
    [self addSubview:self.accessoryLabel];
}

- (void)configureDateCell:(Transaction *)transaction
{
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, 0, 70, self.frame.size.height)];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.text = BC_STRING_DATE;
    self.mainLabel.textColor = [UIColor lightGrayColor];
    [self addSubview:self.mainLabel];

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setAMSymbol:@"am"];
    [dateFormatter setPMSymbol:@"pm"];
    [dateFormatter setDateFormat:@"MMMM dd, yyyy @ h:mmaa"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:transaction.time];
    NSString *dateString = [dateFormatter stringFromDate:date];
    
    CGFloat accessoryLabelXPosition = self.mainLabel.frame.origin.x + self.mainLabel.frame.size.width + 8;
    self.accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(accessoryLabelXPosition, 0, self.frame.size.width - self.contentView.layoutMargins.right - accessoryLabelXPosition, self.frame.size.height)];
    self.accessoryLabel.adjustsFontSizeToFitWidth = YES;
    self.accessoryLabel.textAlignment = NSTextAlignmentRight;
    self.accessoryLabel.text = dateString;
    [self addSubview:self.accessoryLabel];
}

- (void)configureStatusCell:(Transaction *)transaction
{
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, 0, 70, self.frame.size.height)];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.text = BC_STRING_STATUS;
    self.mainLabel.textColor = [UIColor lightGrayColor];
    [self addSubview:self.mainLabel];

    CGFloat accessoryButtonXPosition = self.mainLabel.frame.origin.x + self.mainLabel.frame.size.width + 8;
    self.accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(accessoryButtonXPosition, 0, self.frame.size.width - self.contentView.layoutMargins.right - accessoryButtonXPosition, self.frame.size.height)];
    NSString *buttonTitle = transaction.confirmations >= kConfirmationThreshold ? BC_STRING_CONFIRMED : [NSString stringWithFormat:BC_STRING_PENDING_ARGUMENT_CONFIRMATIONS, [NSString stringWithFormat:@"%u/%u", transaction.confirmations, kConfirmationThreshold]];

    self.accessoryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.accessoryButton addTarget:self action:@selector(showWebviewDetail) forControlEvents:UIControlEventTouchUpInside];
    [self.accessoryButton setTitle:buttonTitle forState:UIControlStateNormal];
    self.accessoryButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.accessoryButton setTitleColor:COLOR_BUTTON_BLUE forState:UIControlStateNormal];
    [self addSubview:self.accessoryButton];
}

- (void)addPlaceholderLabel
{
    self.textViewPlaceholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x - 8, self.textView.frame.origin.y, self.textView.frame.size.width, self.defaultTextViewHeight)];
    self.textViewPlaceholderLabel.textAlignment = NSTextAlignmentRight;
    self.textViewPlaceholderLabel.font = [self.textView.font fontWithSize:self.textView.font.pointSize];
    self.textViewPlaceholderLabel.textColor = [UIColor lightGrayColor];
    NSString *label = [self.detailViewDelegate getNotePlaceholder];
    self.textViewPlaceholderLabel.text = label && label.length > 0 ? label : BC_STRING_TRANSACTION_DESCRIPTION_PLACEHOLDER;
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

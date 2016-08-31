//
//  TransactionDetailTableCell.m
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailTableCell.h"

@implementation TransactionDetailTableCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.textLabel.text = nil;
    [self.textView removeFromSuperview];
    [self.topLabel removeFromSuperview];
    [self.bottomLabel removeFromSuperview];
    [self.topAccessoryLabel removeFromSuperview];
    [self.bottomAccessoryLabel removeFromSuperview];
}

- (void)addTextView
{
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(self.frame.size.width/2, self.contentView.layoutMargins.top, self.frame.size.width/2 - self.contentView.layoutMargins.right, self.frame.size.height - self.contentView.layoutMargins.top - self.contentView.layoutMargins.bottom)];
    self.textView.scrollEnabled = NO;
    self.textView.textAlignment = NSTextAlignmentRight;
    [self.textView setFont:[UIFont systemFontOfSize:15]];
    
    self.defaultTextViewHeight = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)].height;
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width, self.defaultTextViewHeight);
    
    self.textView.delegate = self;
    [self addSubview:self.textView];
    [self addPlaceholderLabel];
}

- (void)addToAndFromLabels
{
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.frame.size.height/2 - 30 - 4, 70, 30)];
    self.topLabel.text = BC_STRING_TO;
    [self addSubview:self.topLabel];

    self.bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.frame.size.height/2 + 4, 70, 30)];
    self.bottomLabel.text = BC_STRING_FROM;
    [self addSubview:self.bottomLabel];
    
    self.topAccessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - self.contentView.layoutMargins.right - 70, self.topLabel.frame.origin.y, 70, 30)];
    self.topAccessoryLabel.textAlignment = NSTextAlignmentRight;
    self.topAccessoryLabel.text = [NSString stringWithFormat:BC_STRING_ARGUMENT_RECIPIENTS, @"2"];
    [self addSubview:self.topAccessoryLabel];

    self.bottomAccessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - self.contentView.layoutMargins.right - 70, self.bottomLabel.frame.origin.y, 70, 30)];
    self.bottomAccessoryLabel.textAlignment = NSTextAlignmentRight;
    self.bottomAccessoryLabel.text = BC_STRING_ADDRESS;
    [self addSubview:self.bottomAccessoryLabel];
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

//
//  TransactionDetailDescriptionCell.m
//  Blockchain
//
//  Created by Kevin Wu on 9/27/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailDescriptionCell.h"

@implementation TransactionDetailDescriptionCell

- (void)configureWithTransaction:(Transaction *)transaction
{
    [super configureWithTransaction:transaction];
    
    if (self.isSetup) {
        self.textLabel.text = BC_STRING_DESCRIPTION;
        if (transaction.note.length > 0) {
            self.textView.text = transaction.note;
        } else {
            NSString *label = [self.descriptionDelegate getNotePlaceholder];
            self.textViewPlaceholderLabel.text = label && label.length > 0 ? label : BC_STRING_TRANSACTION_DESCRIPTION_PLACEHOLDER;
        }
        self.editButton.hidden = NO;
        self.editButton.frame = CGRectMake(self.textView.frame.origin.x + self.textView.frame.size.width, 0, self.contentView.frame.size.width - (self.textView.frame.origin.x + self.textView.frame.size.width), [self.descriptionDelegate getDefaultRowHeight]);
        
        return;
    }
    
    self.textLabel.text = BC_STRING_DESCRIPTION;
    self.textLabel.adjustsFontSizeToFitWidth = YES;
    self.textLabel.textColor = [UIColor lightGrayColor];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width/2, self.contentView.layoutMargins.top, self.contentView.frame.size.width/2 - self.contentView.layoutMargins.right, self.contentView.frame.size.height - self.contentView.layoutMargins.top - self.contentView.layoutMargins.bottom)];
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textView.scrollEnabled = YES;
    self.textView.showsVerticalScrollIndicator = NO;
    self.textView.textAlignment = NSTextAlignmentRight;
    [self.textView setFont:[UIFont systemFontOfSize:15]];
    
    CGFloat sizeThatFitsHeight = [self.textView sizeThatFits:CGSizeMake(self.textView.frame.size.width, FLT_MAX)].height;
    self.defaultTextViewHeight = sizeThatFitsHeight > [self.descriptionDelegate getMaxTextViewHeight] ? [self.descriptionDelegate getMaxTextViewHeight] : sizeThatFitsHeight;
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width - self.defaultTextViewHeight, self.defaultTextViewHeight);

    self.textView.delegate = self;
    [self.contentView addSubview:self.textView];
    self.textView.userInteractionEnabled = NO;
    
    [self addEditButton];
    
    if (transaction.note.length > 0) {
        self.textView.text = transaction.note;
    } else {
        [self addPlaceholderLabel];
    }
    
    self.isSetup = YES;
}

- (void)addEditButton
{
    self.editButton = [[UIButton alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x + self.textView.frame.size.width, 0, self.contentView.frame.size.width - (self.textView.frame.origin.x + self.textView.frame.size.width), [self.descriptionDelegate getDefaultRowHeight])];
    [self.editButton setImage:[UIImage imageNamed:@"pencil"] forState:UIControlStateNormal];
    [self.editButton setImage:[self.editButton.imageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    [self.editButton.imageView setTintColor:[UIColor lightGrayColor]];
    self.editButton.imageEdgeInsets = UIEdgeInsetsMake(20, 10, 20, 19);
    self.editButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.editButton addTarget:self action:@selector(editDescription) forControlEvents:UIControlEventTouchUpInside];
    [self.contentView addSubview:self.editButton];
}

- (void)addPlaceholderLabel
{
    self.textViewPlaceholderLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x - 8, self.textView.frame.origin.y, self.textView.frame.size.width, self.defaultTextViewHeight)];
    self.textViewPlaceholderLabel.textAlignment = NSTextAlignmentRight;
    self.textViewPlaceholderLabel.font = [self.textView.font fontWithSize:self.textView.font.pointSize];
    self.textViewPlaceholderLabel.textColor = [UIColor lightGrayColor];
    NSString *label = [self.descriptionDelegate getNotePlaceholder];
    self.textViewPlaceholderLabel.text = label && label.length > 0 ? label : BC_STRING_TRANSACTION_DESCRIPTION_PLACEHOLDER;
    self.textViewPlaceholderLabel.adjustsFontSizeToFitWidth = YES;
    [self.contentView addSubview:self.textViewPlaceholderLabel];
}

- (void)editDescription
{
    self.editButton.hidden = YES;
    self.textView.userInteractionEnabled = YES;
    [self.textView becomeFirstResponder];
    
    if (self.textView.text.length > 0) {
        NSRange bottom = NSMakeRange(self.textView.text.length -1, 1);
        [self.textView scrollRangeToVisible:bottom];
    }
}

#pragma mark - TextView delegate

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        [self addPlaceholderLabel];
    } else {
        [self.textViewPlaceholderLabel removeFromSuperview];
    }
    
    [self.descriptionDelegate textViewDidChange:textView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return textView.text.length + (text.length - range.length) <= TRANSACTION_DESCRIPTION_CHARACTER_LIMIT;
}

@end

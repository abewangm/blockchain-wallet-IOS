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
        self.mainLabel.text = BC_STRING_DESCRIPTION;
        if (transaction.note.length > 0) {
            self.textView.text = transaction.note;
            self.textViewPlaceholderLabel.hidden = YES;
        } else {
            self.textView.text = nil;
            self.textViewPlaceholderLabel.hidden = NO;
            NSString *label = [self.descriptionDelegate getNotePlaceholder];
            self.textViewPlaceholderLabel.text = label && label.length > 0 ? label : BC_STRING_TRANSACTION_DESCRIPTION_PLACEHOLDER;
        }
        self.editButton.hidden = NO;
        
        return;
    }
    
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.contentView.frame.size.height/2 - 20.5/2, 100, 20.5)];
    self.mainLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:self.mainLabel.font.pointSize];
    self.mainLabel.text = BC_STRING_DESCRIPTION;
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [self.contentView addSubview:self.mainLabel];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(0, 0, 160, 0)];
    self.textView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.textView.scrollEnabled = NO;
    self.textView.showsVerticalScrollIndicator = NO;
    self.textView.textAlignment = NSTextAlignmentRight;
    [self.textView setFont:[UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:15]];
    self.textView.textColor = COLOR_TEXT_DARK_GRAY;
    
    self.textView.frame = CGRectMake(self.textView.frame.origin.x, self.textView.frame.origin.y, self.textView.frame.size.width - self.defaultTextViewHeight, self.defaultTextViewHeight);
    
    self.textView.delegate = self;
    [self.contentView addSubview:self.textView];
    self.textView.editable = NO;
    
    [self addEditButton];
    
    [self addPlaceholderLabel];

    if (transaction.note.length > 0) {
        self.textView.text = transaction.note;
        if (!self.descriptionDelegate.didSetTextViewCursorPosition) {
            [self.descriptionDelegate setDefaultTextViewCursorPosition:self.textView.text.length];
        }
        self.textViewPlaceholderLabel.hidden = YES;
    } else {
        self.textViewPlaceholderLabel.hidden = NO;
    }
    
    self.mainLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.textView.translatesAutoresizingMaskIntoConstraints = NO;
    self.editButton.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.mainLabel
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.f constant:15]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.mainLabel
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.f constant:23]];
    
    [self.contentView addConstraint: [NSLayoutConstraint constraintWithItem:self.textView
                                                                  attribute:NSLayoutAttributeLeft
                                                                  relatedBy:NSLayoutRelationEqual
                                                                     toItem:self.mainLabel
                                                                  attribute:NSLayoutAttributeRight
                                                                 multiplier:1.f constant:16]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.textView
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.editButton
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.f constant:0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:nil
                                                                 attribute:NSLayoutAttributeNotAnAttribute
                                                                multiplier:1.f constant:49]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton
                                                                 attribute:NSLayoutAttributeRight
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeRight
                                                                multiplier:1.f constant:0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.textView
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.f constant:16]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.textView
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.f constant:-16]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton
                                                                 attribute:NSLayoutAttributeTop
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeTop
                                                                multiplier:1.f constant:0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.editButton
                                                                 attribute:NSLayoutAttributeBottom
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.contentView
                                                                 attribute:NSLayoutAttributeBottom
                                                                multiplier:1.f constant:0]];
    
    self.isSetup = YES;
}

- (void)addEditButton
{
    self.editButton = [[UIButton alloc] initWithFrame:CGRectMake(self.textView.frame.origin.x + self.textView.frame.size.width, 0, self.contentView.frame.size.width - (self.textView.frame.origin.x + self.textView.frame.size.width), [self.descriptionDelegate getDefaultRowHeight])];
    [self.editButton addTarget:self action:@selector(editDescription) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat pencilImageViewHeight = 24;
    UIImageView *pencilImageView = [[UIImageView alloc] initWithFrame:CGRectMake(10, 20, pencilImageViewHeight, pencilImageViewHeight)];
    pencilImageView.image = [UIImage imageNamed:@"pencil"];
    pencilImageView.image = [pencilImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [pencilImageView setTintColor:COLOR_PENCIL_LIGHT_GRAY];
    pencilImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.editButton addSubview:pencilImageView];
    
    [self.editButton bringSubviewToFront:pencilImageView];
    
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
    
    self.textViewPlaceholderLabel.translatesAutoresizingMaskIntoConstraints = NO;
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.textViewPlaceholderLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.mainLabel
                                                                 attribute:NSLayoutAttributeCenterY
                                                                multiplier:1.f constant:0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.textViewPlaceholderLabel
                                                                 attribute:NSLayoutAttributeLeft
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.textView
                                                                 attribute:NSLayoutAttributeLeft
                                                                multiplier:1.f constant:0]];
    
    [self.contentView addConstraint:[NSLayoutConstraint constraintWithItem:self.textViewPlaceholderLabel
                                                                 attribute:NSLayoutAttributeWidth
                                                                 relatedBy:NSLayoutRelationEqual
                                                                    toItem:self.textView
                                                                 attribute:NSLayoutAttributeWidth
                                                                multiplier:1.f constant:0]];
}

- (void)editDescription
{
    self.editButton.hidden = YES;
    self.textView.editable = YES;
    self.textView.inputAccessoryView = [self.descriptionDelegate getDescriptionInputAccessoryView];
    
    [self.textView becomeFirstResponder];
        
    NSRange cursorPosition = [self.descriptionDelegate getTextViewCursorPosition];
    self.textView.selectedRange = cursorPosition;
    
    [self.descriptionDelegate textViewDidChange:self.textView];
}

#pragma mark - TextView delegate

- (void)textViewDidChange:(UITextView *)textView
{
    if ([textView.text isEqualToString:@""]) {
        self.textViewPlaceholderLabel.hidden = NO;
    } else {
        self.textViewPlaceholderLabel.hidden = YES;
    }
    
    [self.descriptionDelegate textViewDidChange:textView];
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    return textView.text.length + (text.length - range.length) <= TRANSACTION_DESCRIPTION_CHARACTER_LIMIT;
}

@end

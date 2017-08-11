//
//  BCSummaryView.m
//  Blockchain
//
//  Created by kevinwu on 8/8/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCSummaryView.h"
@interface BCSummaryView ()
@end
@implementation BCSummaryView

#pragma mark - Description Delegate

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self == [super initWithFrame:frame]) {
        [self setupTextViewInputAccessoryView];
    }
    return self;
}

- (void)textViewDidChange:(UITextView *)textView
{
    CGPoint currentOffset = self.tableView.contentOffset;
    [UIView setAnimationsEnabled:NO];
    [self.tableView beginUpdates];
    [self.tableView endUpdates];
    [UIView setAnimationsEnabled:YES];
    self.tableView.contentOffset = currentOffset;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        CGRect keyboardAccessoryRect = [self.descriptionInputAccessoryView.superview convertRect:self.descriptionInputAccessoryView.frame toView:self.tableView];
        CGRect keyboardPlusAccessoryRect = CGRectMake(keyboardAccessoryRect.origin.x, keyboardAccessoryRect.origin.y, keyboardAccessoryRect.size.width, self.frame.size.height - keyboardAccessoryRect.origin.y);
        
        UITextRange *selectionRange = [textView selectedTextRange];
        CGRect selectionEndRect = [textView convertRect:[textView caretRectForPosition:selectionRange.end] toView:self.tableView];
        
        if (CGRectIntersectsRect(keyboardPlusAccessoryRect, selectionEndRect)) {
            [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y + selectionEndRect.origin.y + selectionEndRect.size.height - keyboardAccessoryRect.origin.y + 15) animated:NO];
        }
    });
}

- (UIView *)getDescriptionInputAccessoryView
{
    return self.textView.isEditable ? self.descriptionInputAccessoryView : nil;
}

- (CGFloat)getDefaultRowHeight
{
    return CELL_HEIGHT;
}

- (void)setupTextViewInputAccessoryView
{
    UIView *inputAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, BUTTON_HEIGHT)];
    inputAccessoryView.backgroundColor = COLOR_WARNING_RED;
    
    UIButton *updateButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, BUTTON_HEIGHT)];
    updateButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    [updateButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [updateButton.titleLabel setFont:[UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:updateButton.titleLabel.font.pointSize]];
    [updateButton setTitle:BC_STRING_UPDATE forState:UIControlStateNormal];
    [updateButton addTarget:self action:@selector(saveNote) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:updateButton];
    
    UIButton *cancelButton = [[UIButton alloc] initWithFrame:CGRectMake(updateButton.frame.size.width - 50, 0, 50, BUTTON_HEIGHT)];
    cancelButton.backgroundColor = COLOR_BUTTON_GRAY_CANCEL;
    [cancelButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [cancelButton addTarget:self action:@selector(cancelEditing) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:cancelButton];
    
    self.descriptionInputAccessoryView = inputAccessoryView;
}

- (void)cancelEditing
{
    self.textViewCursorPosition = self.textView.selectedRange;
    
    [self.textView resignFirstResponder];
    self.textView.editable = NO;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:cellRowDescription inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    });
}

- (NSString *)getNotePlaceholder
{
    return nil;
}

- (NSRange)getTextViewCursorPosition
{
    return self.textViewCursorPosition;
}

- (void)setDefaultTextViewCursorPosition:(NSUInteger)textLength
{
    self.textViewCursorPosition = NSMakeRange(textLength, 0);
    _didSetTextViewCursorPosition = YES;
}

- (CGFloat)tableView:(UITableView *)tableView estimatedHeightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (void)saveNote
{
    
}

@end

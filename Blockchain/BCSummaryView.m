//
//  BCSummaryView.m
//  Blockchain
//
//  Created by kevinwu on 8/8/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCSummaryView.h"
#import "BCLine.h"
#import "UIView+ChangeFrameAttribute.h"

@interface BCSummaryView ()
@property (nonatomic) BOOL startedEditing;
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

- (void)textViewDidBeginEditing:(UITextView *)textView
{
    self.startedEditing = YES;
    [self moveViewsUpForSmallScreens];
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
            [self.tableView setContentOffset:CGPointMake(0, self.tableView.contentOffset.y + selectionEndRect.origin.y + selectionEndRect.size.height - keyboardAccessoryRect.origin.y + 15) animated:self.startedEditing];
        }
    });

    if (self.startedEditing) {
        self.startedEditing = NO;
    } else {
        [self adjustHeightOfTableViewAnimated:NO];
    }
}

- (void)adjustHeightOfTableViewAnimated:(BOOL)animated
{
    CGFloat height = self.tableView.contentSize.height;
    CGFloat maxHeight = self.tableView.superview.frame.size.height - self.topView.frame.size.height - 8 - self.footerView.frame.size.height - 8 - BUTTON_HEIGHT - 8;
    
    if (height > maxHeight) {
        height = maxHeight;
        self.tableView.scrollEnabled = YES;
    } else {
        self.tableView.scrollEnabled = NO;
    }
    
    CGRect frame = self.tableView.frame;
    frame.size.height = height;
    
    if (animated) {
        [UIView animateWithDuration:ANIMATION_DURATION_LONG animations:^{
            self.tableView.frame = frame;
            [self.footerView changeYPosition:frame.origin.y + frame.size.height + 8];
        }];
    } else {
        self.tableView.frame = frame;
        [self.footerView changeYPosition:frame.origin.y + frame.size.height + 8];
    }
    
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
    inputAccessoryView.backgroundColor = [UIColor whiteColor];;
    
    BCLine *topLine = [[BCLine alloc] initWithYPosition:0];
    [inputAccessoryView addSubview:topLine];
    
    BCLine *bottomLine = [[BCLine alloc] initWithYPosition:0];
    [inputAccessoryView addSubview:bottomLine];
    
    UIButton *doneButton = [[UIButton alloc] initWithFrame:CGRectMake(inputAccessoryView.frame.size.width - 68, 0, 60, BUTTON_HEIGHT)];
    doneButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:13.0];
    [doneButton setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateNormal];
    [doneButton setTitle:BC_STRING_DONE forState:UIControlStateNormal];
    [doneButton addTarget:self action:@selector(cancelEditing) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:doneButton];
    
    self.descriptionInputAccessoryView = inputAccessoryView;
}

- (void)cancelEditing
{
    self.textViewCursorPosition = self.textView.selectedRange;
    
    [self.textView resignFirstResponder];
    self.textView.editable = NO;
    
    // Re-enable editing
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:cellRowDescription inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
    });
    
    [self moveViewsDownForSmallScreens];
    
    [self adjustHeightOfTableViewAnimated:YES];
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

#pragma mark - View Helpers

- (void)moveViewsUpForSmallScreens
{
    if (IS_USING_SCREEN_SIZE_4S) {
        
        self.topView.hidden = YES;
        
        [UIView animateWithDuration:ANIMATION_DURATION_LONG animations:^{
            [self.tableView changeYPosition:0];
        }];
    }
}

- (void)moveViewsDownForSmallScreens
{
    if (IS_USING_SCREEN_SIZE_4S) {
        
        self.topView.alpha = 0;
        self.topView.hidden = NO;
        
        [UIView animateWithDuration:ANIMATION_DURATION_LONG animations:^{
            [self.tableView changeYPosition:self.topView.frame.origin.y + self.topView.frame.size.height];
        } completion:^(BOOL finished) {
            [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                self.topView.alpha = 1;
            }];
        }];
    }
}

@end

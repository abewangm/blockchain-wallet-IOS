//
//  BCDescriptionView.m
//  Blockchain
//
//  Created by kevinwu on 8/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCDescriptionView.h"
#import "UIView+ChangeFrameAttribute.h"
#import "BCLine.h"

@implementation BCDescriptionView

- (instancetype)initWithFrame:(CGRect)frame
{
    if (self = [super initWithFrame:frame]) {
        self.descriptionCellHeight = 140;
        [self setupTextViewInputAccessoryView];
    }
    return self;
}

- (void)endEditingDescription
{
    self.note = self.descriptionTextView.text;
    
    self.isEditingDescription = NO;
    
    [self.descriptionTextView resignFirstResponder];
    
    [self moveViewsDownForSmallScreens];
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

- (void)beginEditingDescription
{
    [self moveViewsUpForSmallScreens];
    
    self.isEditingDescription = YES;
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationFade];
}

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

#pragma mark - View Helpers

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
    [doneButton addTarget:self action:@selector(endEditingDescription) forControlEvents:UIControlEventTouchUpInside];
    [inputAccessoryView addSubview:doneButton];
    
    self.descriptionInputAccessoryView = inputAccessoryView;
}

- (UITableViewCell *)configureDescriptionTextViewForCell:(UITableViewCell *)cell
{
    cell.textLabel.text = BC_STRING_DESCRIPTION;

    self.descriptionTextView = [[UITextView alloc] initWithFrame:CGRectMake(cell.contentView.frame.size.width/2 + 8, 8, cell.contentView.frame.size.width/2 - 8 - 8, self.descriptionCellHeight - 16)];
    self.descriptionTextView.textColor = COLOR_TEXT_DARK_GRAY;
    self.descriptionTextView.textContainerInset = UIEdgeInsetsZero;
    self.descriptionTextView.textAlignment = NSTextAlignmentRight;
    self.descriptionTextView.autocorrectionType = UITextAutocorrectionTypeNo;
    self.descriptionTextView.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    self.descriptionTextView.inputAccessoryView = self.descriptionInputAccessoryView;
    self.descriptionTextView.text = self.note;
    [cell.contentView addSubview:self.descriptionTextView];
    
    [self.descriptionTextView becomeFirstResponder];
    
    return cell;
}

@end

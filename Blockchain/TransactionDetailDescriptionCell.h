//
//  TransactionDetailDescriptionCell.h
//  Blockchain
//
//  Created by Kevin Wu on 9/27/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransactionDetailTableCell.h"

@protocol DescriptionDelegate
- (void)textViewDidChange:(UITextView *)textView;
- (NSString *)getNotePlaceholder;
- (CGFloat)getDefaultRowHeight;
@end
@interface TransactionDetailDescriptionCell : TransactionDetailTableCell
@property (nonatomic) UITextView *textView;
@property (nonatomic) UILabel *textViewPlaceholderLabel;
@property (nonatomic) CGFloat defaultTextViewHeight;
@property (nonatomic) UIButton *editButton;
@property (nonatomic) id<DescriptionDelegate> descriptionDelegate;
- (void)addEditButton;

@end

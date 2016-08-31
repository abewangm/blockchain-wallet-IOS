//
//  TransactionDetailTableCell.h
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol DetailViewDelegate
- (void)textViewDidChange:(UITextView *)textView;
@end

@interface TransactionDetailTableCell : UITableViewCell <UITextViewDelegate>
@property (nonatomic) UITextView *textView;
@property (nonatomic) UILabel *textViewPlaceholderLabel;
@property (nonatomic) CGFloat defaultTextViewHeight;

@property (nonatomic) UILabel *topLabel;
@property (nonatomic) UILabel *bottomLabel;
@property (nonatomic) UILabel *topAccessoryLabel;
@property (nonatomic) UILabel *bottomAccessoryLabel;

@property (nonatomic) id<DetailViewDelegate> detailViewDelegate;

- (void)addTextView;
- (void)addToAndFromLabels;
- (void)addPlaceholderLabel;
@end

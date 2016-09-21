//
//  TransactionDetailTableCell.h
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Transaction.h"

@protocol DetailDelegate
- (void)textViewDidChange:(UITextView *)textView;
- (void)toggleSymbol;
- (void)showWebviewDetail;
- (NSString *)getNotePlaceholder;
- (NSString *)getCurrencyCode;
- (CGFloat)getDefaultRowHeight;
@end

@interface TransactionDetailTableCell : UITableViewCell <UITextViewDelegate>

// Value cell
@property (nonatomic) UIButton *amountButton;
@property (nonatomic) UILabel *fiatValueWhenSentLabel;
@property (nonatomic) UILabel *transactionFeeLabel;

// Description cell
@property (nonatomic) UITextView *textView;
@property (nonatomic) UILabel *textViewPlaceholderLabel;
@property (nonatomic) CGFloat defaultTextViewHeight;
@property (nonatomic) UIButton *editButton;

// Generic/To and From cell
@property (nonatomic) UILabel *mainLabel;
@property (nonatomic) UILabel *accessoryLabel;
@property (nonatomic) UIButton *accessoryButton;

@property (nonatomic) id<DetailDelegate> detailViewDelegate;

- (void)configureDescriptionCell:(Transaction *)transaction;
- (void)configureToCell:(Transaction *)transaction;
- (void)configureFromCell:(Transaction *)transaction;
- (void)configureDateCell:(Transaction *)transaction;
- (void)configureStatusCell:(Transaction *)transaction;
- (void)configureValueCell:(Transaction *)transaction;

- (void)addEditButton;

@end

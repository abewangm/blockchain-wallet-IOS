//
//  BCSummaryView.h
//  Blockchain
//
//  Created by kevinwu on 8/8/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransactionDetailDescriptionCell.h"

#define CELL_HEIGHT_DESCRIPTION_CELL 44.0f
#define SPACING_TEXTVIEW 5.6f

@interface BCSummaryView : UIView <DescriptionDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITextView *textView;
@property (nonatomic) NSRange textViewCursorPosition;
@property (nonatomic) UIView *descriptionInputAccessoryView;
@property (nonatomic, readonly) BOOL didSetTextViewCursorPosition;
@property (nonatomic) NSString *note;
@property (nonatomic) NSUInteger numberOfRows;
@property (nonatomic) UIView *topView;
@property (nonatomic) UIView *footerView;
@property (nonatomic) NSInteger cellRowDescription;

- (void)cancelEditing;

@end

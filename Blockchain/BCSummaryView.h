//
//  BCSummaryView.h
//  Blockchain
//
//  Created by kevinwu on 8/8/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "TransactionDetailDescriptionCell.h"

#define CELL_HEIGHT 44

const int cellRowDescription = 2;

@interface BCSummaryView : UIView <DescriptionDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UITextView *textView;
@property (nonatomic) NSRange textViewCursorPosition;
@property (nonatomic) UIView *descriptionInputAccessoryView;
@property (nonatomic, readonly) BOOL didSetTextViewCursorPosition;
@property (nonatomic) NSString *note;
@end

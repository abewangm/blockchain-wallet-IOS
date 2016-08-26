//
//  TransactionDetailTableCell.h
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface TransactionDetailTableCell : UITableViewCell
@property (nonatomic) UITextView *textView;
@property (nonatomic) UILabel *topLabel;
@property (nonatomic) UILabel *bottomLabel;

- (void)addTextView;
- (void)addToAndFromLabels;
@end

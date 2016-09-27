//
//  TransactionDetailTableCell.h
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Transaction.h"

@interface TransactionDetailTableCell : UITableViewCell <UITextViewDelegate>
@property (nonatomic) BOOL isSetup;

- (void)configureWithTransaction:(Transaction *)transaction;

@end

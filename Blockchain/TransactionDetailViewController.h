//
//  TransactionDetailViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 8/23/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Transaction.h"

@interface TransactionDetailViewController : UIViewController

@property (nonatomic) Transaction *transaction;
@property (nonatomic) NSUInteger transactionIndex;
@property (nonatomic) NSUInteger transactionCount;

@end

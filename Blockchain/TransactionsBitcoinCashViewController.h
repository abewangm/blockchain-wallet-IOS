//
//  TransactionsBitcoinCashViewController.h
//  Blockchain
//
//  Created by kevinwu on 2/21/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class TransactionDetailViewController;
@interface TransactionsBitcoinCashViewController : UIViewController
@property(nonatomic) TransactionDetailViewController *detailViewController;
- (void)reload;
@end

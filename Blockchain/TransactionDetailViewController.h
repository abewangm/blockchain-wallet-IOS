//
//  TransactionDetailViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 8/23/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Transaction.h"
@protocol BusyViewDelegate
- (void)showBusyViewWithLoadingText:(NSString *)text;
- (void)hideBusyView;
@end
@interface TransactionDetailViewController : UIViewController

@property (nonatomic) Transaction *transaction;
@property (nonatomic) id<BusyViewDelegate> busyViewDelegate;
@property (nonatomic, readonly) BOOL didSetTextViewCursorPosition;

- (void)reloadSymbols;
- (void)didGetHistory;

@end

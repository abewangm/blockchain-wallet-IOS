//
//  ExchangeDetailView.h
//  Blockchain
//
//  Created by Maurice A. on 11/20/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExchangeDetailView : UIView
- (void)createPseudoTableWithDepositAmount:(NSString *)depositAmount receiveAmount:(NSString *)receiveAmount exchangeRate:(NSString *)exchangeRate transactionFee:(NSString *)transactionFee networkTransactionFee:(NSString *)networkTransactionFee;
@end

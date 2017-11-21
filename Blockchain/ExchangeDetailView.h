//
//  ExchangeDetailView.h
//  Blockchain
//
//  Created by Maurice A. on 11/20/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExchangeDetailView : UIView
- (void)createPseudoTableWith:(NSString *)depositAmount receiveAmount:(NSString *)recAmt exchangeRate:(NSString *)rate transactionFee:(NSString *)fee networkTransactionFee:(NSString *)netwkFee;
@end

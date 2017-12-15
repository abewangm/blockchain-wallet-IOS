//
//  ExchangeOverviewViewController.h
//  Blockchain
//
//  Created by kevinwu on 10/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ExchangeOverviewViewController : UIViewController
- (void)didGetExchangeTrades:(NSArray *)trades;
- (void)didGetExchangeRate:(NSDictionary *)result;
- (void)didGetQuote:(NSDictionary *)result;
- (void)didGetAvailableEthBalance:(NSDictionary *)result;
- (void)didGetAvailableBtcBalance:(NSDictionary *)result;
- (void)didBuildExchangeTrade:(NSDictionary *)tradeInfo;
- (void)didShiftPayment:(NSDictionary *)info;
- (void)reloadSymbols;
@end

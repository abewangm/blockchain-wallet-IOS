//
//  BCBalancesChartView.h
//  Blockchain
//
//  Created by kevinwu on 2/1/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCBalancesChartView : UIView

- (void)updateBitcoinBalance:(double)balance;
- (void)updateEtherBalance:(double)balance;
- (void)updateBitcoinCashBalance:(double)balance;
- (void)updateTotalBalance:(NSString *)balance;
- (void)updateChart;

@end

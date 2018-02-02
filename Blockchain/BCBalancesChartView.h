//
//  BCBalancesChartView.h
//  Blockchain
//
//  Created by kevinwu on 2/1/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCBalancesChartView : UIView

- (void)updateBitcoinBalance:(uint64_t)balance;
- (void)updateEtherBalance:(NSString *)balance;
- (void)updateBitcoinCashBalance:(uint64_t)balance;
- (void)updateChart;

@end

//
//  BCPriceChartView.h
//  Blockchain
//
//  Created by kevinwu on 1/31/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

#define USER_DEFAULTS_KEY_GRAPH_TIME_FRAME @"timeFrame"

@class ChartAxisBase, ChartDataEntry;
@protocol BCPriceChartViewDelegate
- (void)reloadPriceChartView;
@end

@interface BCPriceChartView : UIView
- (void)updateWithValues:(NSArray *)values;
- (void)clear;
- (void)updateEthExchangeRate:(NSDecimalNumber *)rate;
- (void)updateTitleContainer;
- (void)updateTitleContainerWithChartDataEntry:(ChartDataEntry *)dataEntry;
- (ChartAxisBase *)leftAxis;
- (ChartAxisBase *)xAxis;
@end

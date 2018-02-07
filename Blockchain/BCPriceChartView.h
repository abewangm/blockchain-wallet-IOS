//
//  BCPriceChartView.h
//  Blockchain
//
//  Created by kevinwu on 1/31/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Assets.h"

#define USER_DEFAULTS_KEY_GRAPH_TIME_FRAME @"timeFrame"

@class ChartAxisBase, ChartDataEntry;
@protocol IChartAxisValueFormatter;
@protocol BCPriceChartViewDelegate
- (void)reloadPriceChartView:(AssetType)assetType;
@end

@interface BCPriceChartView : UIView
- (id)initWithFrame:(CGRect)frame assetType:(AssetType)assetType dataPoints:(NSArray *)dataPoints delegate:(id<IChartAxisValueFormatter, BCPriceChartViewDelegate>)delegate;

- (void)updateWithValues:(NSArray *)values;
- (void)clear;
- (void)updateTitleContainer;
- (void)updateTitleContainerWithChartDataEntry:(ChartDataEntry *)dataEntry;
- (void)updateEthExchangeRate:(NSString *)rate;
- (ChartAxisBase *)leftAxis;
- (ChartAxisBase *)xAxis;
@end

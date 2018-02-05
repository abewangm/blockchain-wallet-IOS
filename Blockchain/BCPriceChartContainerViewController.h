//
//  BCPriceChartContainerViewController.h
//  Blockchain
//
//  Created by kevinwu on 2/5/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BCPriceChartView, ChartDataEntry, ChartAxisBase;
@interface BCPriceChartContainerViewController : UIViewController
- (void)addPriceChartView:(BCPriceChartView *)priceChartView;
- (void)clearChart;
- (void)updateChartWithValues:(NSArray *)values;
- (ChartAxisBase *)leftAxis;
- (ChartAxisBase *)xAxis;
- (void)updateTitleContainer;
- (void)updateTitleContainerWithChartDataEntry:(ChartDataEntry *)entry;
@end

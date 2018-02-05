//
//  BCPriceChartContainerViewController.m
//  Blockchain
//
//  Created by kevinwu on 2/5/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCPriceChartContainerViewController.h"
#import "BCPriceChartView.h"
@class ChartAxisBase;
@interface BCPriceChartContainerViewController ()
@property BCPriceChartView *priceChartView;
@end

@implementation BCPriceChartContainerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [[UIColor blackColor] colorWithAlphaComponent:BUSY_VIEW_LABEL_ALPHA];
    
    CGFloat buttonWidth = 50;
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 8 - buttonWidth, 30, buttonWidth, buttonWidth)];
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
}

- (void)closeButtonTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addPriceChartView:(BCPriceChartView *)priceChartView
{
    self.priceChartView = priceChartView;
    [self.view addSubview:priceChartView];
}

- (void)clearChart
{
    [self.priceChartView clear];
}

- (void)updateChartWithValues:(NSArray *)values
{
    [self.priceChartView updateWithValues:values];
}

- (ChartAxisBase *)leftAxis
{
    return [self.priceChartView leftAxis];
}

- (ChartAxisBase *)xAxis
{
    return [self.priceChartView xAxis];
}

- (void)updateTitleContainer
{
    [self.priceChartView updateTitleContainer];
}

- (void)updateTitleContainerWithChartDataEntry:(ChartDataEntry *)entry
{
    [self.priceChartView updateTitleContainerWithChartDataEntry:entry];
}

@end

//
//  BCBalancesChartView.m
//  Blockchain
//
//  Created by kevinwu on 2/1/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCBalancesChartView.h"
#import "UIView+ChangeFrameAttribute.h"

@import Charts;

@interface BCBalancesChartView ()
@property (nonatomic) PieChartView *chartView;
@property (nonatomic) double bitcoinBalance;
@property (nonatomic) double etherBalance;
@property (nonatomic) double bitcoinCashBalance;
@end

@implementation BCBalancesChartView

- (id)initWithFrame:(CGRect)frame
{
    if (self == [super initWithFrame:frame]) {
        [self setupChartViewWithFrame:frame];
        [self setupLegendWithFrame:frame];
    }
    
    return self;
}

- (void)setupChartViewWithFrame:(CGRect)frame
{
    self.chartView = [[PieChartView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height * 3/4)];
    self.chartView.drawCenterTextEnabled = YES;
    self.chartView.centerAttributedText = [self centerText];
    self.chartView.drawHoleEnabled = YES;
    self.chartView.holeColor = [UIColor clearColor];
    self.chartView.holeRadiusPercent = 0.6;
    [self.chartView animateWithYAxisDuration:0.5];
    self.chartView.rotationEnabled = NO;
    self.chartView.legend.enabled = NO;
    self.chartView.chartDescription.enabled = NO;
    self.chartView.transparentCircleColor = [UIColor whiteColor];
    
    [self addSubview:self.chartView];
}

- (void)setupLegendWithFrame:(CGRect)frame
{
    
}

- (void)updateBitcoinBalance:(uint64_t)balance
{
    self.bitcoinBalance = 50.0;
}

- (void)updateEtherBalance:(NSString *)balance
{
    self.etherBalance = 50.0;
}

- (void)updateBitcoinCashBalance:(uint64_t)balance
{
    self.bitcoinCashBalance = 50.0;
}

- (void)updateChart
{
    ChartDataEntry *bitcoinValue = [[PieChartDataEntry alloc] initWithValue:self.bitcoinBalance];
    
    ChartDataEntry *etherValue = [[PieChartDataEntry alloc] initWithValue:self.etherBalance];
    
    ChartDataEntry *bitcoinCashValue = [[PieChartDataEntry alloc] initWithValue:self.bitcoinCashBalance];
    
    PieChartDataSet *dataSet = [[PieChartDataSet alloc] initWithValues:@[bitcoinValue, etherValue, bitcoinCashValue] label:BC_STRING_BALANCES];
    dataSet.drawValuesEnabled = NO;
    
    dataSet.colors = @[COLOR_BLOCKCHAIN_BLUE, COLOR_BLOCKCHAIN_LIGHT_BLUE, COLOR_BLOCKCHAIN_LIGHTEST_BLUE];
    
    PieChartData *data = [[PieChartData alloc] initWithDataSet:dataSet];
    [data setValueTextColor:UIColor.whiteColor];
    self.chartView.data = data;
}

- (NSAttributedString *)centerText
{
    UIFont *font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjects:@[COLOR_TEXT_DARK_GRAY, font] forKeys:@[NSForegroundColorAttributeName, NSFontAttributeName]];
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:@"balance" attributes:attributesDictionary];
    
    return attributedString;
}

@end

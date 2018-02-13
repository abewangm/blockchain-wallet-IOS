//
//  BCBalancesChartView.m
//  Blockchain
//
//  Created by kevinwu on 2/1/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCBalancesChartView.h"
#import "UIView+ChangeFrameAttribute.h"
#import "BCBalanceChartLegendKeyView.h"

#define CHART_VIEW_BOTTOM_PADDING 16

@import Charts;

@interface BCBalancesChartView ()
@property (nonatomic) PieChartView *chartView;
@property (nonatomic) double bitcoinBalance;
@property (nonatomic) double etherBalance;
@property (nonatomic) double bitcoinCashBalance;
@property (nonatomic) BCBalanceChartLegendKeyView *bitcoinLegendKey;
@property (nonatomic) BCBalanceChartLegendKeyView *etherLegendKey;
@property (nonatomic) BCBalanceChartLegendKeyView *bitcoinCashLegendKey;
@end

@implementation BCBalancesChartView

- (id)initWithFrame:(CGRect)frame
{
    if (self == [super initWithFrame:frame]) {
        self.backgroundColor = [UIColor whiteColor];
        [self setupChartViewWithFrame:frame];
        [self setupLegendWithFrame:frame];
    }
    
    return self;
}

- (void)setupChartViewWithFrame:(CGRect)frame
{
    CGFloat bottomPadding = CHART_VIEW_BOTTOM_PADDING;
    self.chartView = [[PieChartView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height * 3/4 - bottomPadding)];
    self.chartView.drawCenterTextEnabled = YES;
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
    CGFloat bottomPadding = CHART_VIEW_BOTTOM_PADDING;
    CGFloat containerViewHorizontalPadding = 20;
    UIView *legendKeyContainerView = [[UIView alloc] initWithFrame:CGRectMake(containerViewHorizontalPadding, frame.size.height * 3/4 - bottomPadding, frame.size.width - containerViewHorizontalPadding*2, (frame.size.height - bottomPadding)/4)];
    [self addSubview:legendKeyContainerView];
    
    CGFloat legendKeySpacing = 12;
    CGFloat legendKeyWidth = (legendKeyContainerView.frame.size.width - legendKeySpacing*2)/3;
    CGFloat legendKeyHeight = legendKeyContainerView.frame.size.height;
    
    self.bitcoinLegendKey = [[BCBalanceChartLegendKeyView alloc] initWithFrame:CGRectMake(0, 0, legendKeyWidth, legendKeyHeight) assetColor:COLOR_BLOCKCHAIN_BLUE assetName:BC_STRING_BITCOIN balance:@"1" fiatBalance:@"$8000"];
    [legendKeyContainerView addSubview:self.bitcoinLegendKey];
    
    self.etherLegendKey = [[BCBalanceChartLegendKeyView alloc] initWithFrame:CGRectMake(legendKeyWidth + legendKeySpacing, 0, legendKeyWidth, legendKeyHeight) assetColor:COLOR_BLOCKCHAIN_LIGHT_BLUE assetName:BC_STRING_ETHER balance:@"1" fiatBalance:@"$1000"];
    [legendKeyContainerView addSubview:self.etherLegendKey];
    
    self.bitcoinCashLegendKey = [[BCBalanceChartLegendKeyView alloc] initWithFrame:CGRectMake((legendKeyWidth + legendKeySpacing)*2, 0, legendKeyWidth, legendKeyHeight) assetColor:COLOR_BLOCKCHAIN_LIGHTEST_BLUE assetName:BC_STRING_BITCOIN_CASH balance:@"1" fiatBalance:@"$5000"];
    [legendKeyContainerView addSubview:self.bitcoinCashLegendKey];
}

- (void)updateBitcoinBalance:(double)balance
{
    self.bitcoinBalance = balance;
}

- (void)updateEtherBalance:(double)balance
{
    self.etherBalance = balance;
}

- (void)updateBitcoinCashBalance:(double)balance
{
    self.bitcoinCashBalance = balance;
}

- (void)updateTotalBalance:(NSString *)balance
{
    self.chartView.centerAttributedText = balance ? [self balanceAttributedStringWithText:balance] : nil;
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

- (NSAttributedString *)balanceAttributedStringWithText:(NSString *)text
{
    UIFont *font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
    
    NSDictionary *attributesDictionary = [NSDictionary dictionaryWithObjects:@[COLOR_TEXT_DARK_GRAY, font] forKeys:@[NSForegroundColorAttributeName, NSFontAttributeName]];
    
    NSAttributedString *attributedString = [[NSAttributedString alloc] initWithString:text attributes:attributesDictionary];
    
    return attributedString;
}

@end

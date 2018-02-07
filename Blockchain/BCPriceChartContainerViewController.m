//
//  BCPriceChartContainerViewController.m
//  Blockchain
//
//  Created by kevinwu on 2/5/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCPriceChartContainerViewController.h"

#define DICTIONARY_KEY_BITCOIN @"bitcoin"
#define DICTIONARY_KEY_ETHER @"ether"
#define DICTIONARY_KEY_BITCOIN_CASH @"bitcoinCash"

@class ChartAxisBase;
@interface BCPriceChartContainerViewController ()
@property (nonatomic) BCPriceChartView *priceChartView;
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) NSMutableDictionary *addedCharts;
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
    
    self.addedCharts = [NSMutableDictionary new];
}

- (void)closeButtonTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)addPriceChartView:(BCPriceChartView *)priceChartView atIndex:(NSInteger)pageIndex
{
    if (!self.scrollView) {
        self.scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, priceChartView.frame.size.height)];
        self.scrollView.center = CGPointMake(self.scrollView.center.x, self.view.frame.size.height/2);
        self.scrollView.contentSize = CGSizeMake(self.view.frame.size.width*3, self.scrollView.frame.size.height);
        self.scrollView.pagingEnabled = YES;
        self.scrollView.scrollEnabled = NO;
        [self.scrollView setContentOffset:CGPointMake(pageIndex * self.scrollView.frame.size.width, 0) animated:NO];
        [self.view addSubview:self.scrollView];
        
        UIPageControl *pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, self.scrollView.frame.origin.y + self.scrollView.frame.size.height + 16, 100, 30)];
        pageControl.numberOfPages = 3;
        [pageControl setCurrentPage:pageIndex];
        [pageControl addTarget:self action:@selector(pageControlChanged:) forControlEvents:UIControlEventValueChanged];
        pageControl.center = CGPointMake(self.view.frame.size.width/2, pageControl.center.y);
        [self.view addSubview:pageControl];
    }

    priceChartView.center = CGPointMake(pageIndex * self.scrollView.frame.size.width + self.scrollView.frame.size.width/2, self.scrollView.frame.size.height/2);
    self.priceChartView = priceChartView;
    [self.scrollView addSubview:priceChartView];
    
    [self.addedCharts setObject:priceChartView forKey:[self dictionaryKeyForPage:pageIndex]];
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

- (void)pageControlChanged:(UIPageControl *)pageControl
{
    [self.scrollView setContentOffset:CGPointMake(pageControl.currentPage * self.scrollView.frame.size.width, 0) animated:YES];
    
    if (![self.addedCharts objectForKey:[self dictionaryKeyForPage:pageControl.currentPage]]) {
        [self.delegate addPriceChartView:pageControl.currentPage];
    } else {
        [self.delegate reloadPriceChartView:pageControl.currentPage];
    }
}

- (void)updateEthExchangeRate:(NSString *)rate
{
    [self.priceChartView updateEthExchangeRate:rate];
}

- (NSString *)dictionaryKeyForPage:(NSInteger)pageIndex
{
    switch (pageIndex) {
        case AssetTypeBitcoin: return DICTIONARY_KEY_BITCOIN;
        case AssetTypeEther: return DICTIONARY_KEY_ETHER;
        case AssetTypeBitcoinCash: return DICTIONARY_KEY_BITCOIN_CASH;
        default: return nil;
    }
}

@end

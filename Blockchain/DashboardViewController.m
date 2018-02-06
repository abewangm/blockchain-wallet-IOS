//
//  DashboardViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/23/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//



#import "DashboardViewController.h"
#import "SessionManager.h"
#import "UIView+ChangeFrameAttribute.h"
#import "NSNumberFormatter+Currencies.h"
#import "RootService.h"
#import "GraphTimeFrame.h"
#import "Blockchain-Swift.h"
#import "BCPriceChartView.h"
#import "BCBalancesChartView.h"
#import "BCPricePreviewView.h"
#import "BCPriceChartContainerViewController.h"

#define DASHBOARD_HORIZONTAL_PADDING 15

@import Charts;

@interface CardsViewController ()
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *contentView;
@end

@interface DashboardViewController () <IChartAxisValueFormatter, ChartViewDelegate, BCPriceChartViewDelegate>
@property (nonatomic) BCBalancesChartView *balancesChartView;
@property (nonatomic) BCPriceChartContainerViewController *chartContainerViewController;
@end

@implementation DashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This contentView can be any custom view - intended to be placed at the top of the scroll view, moved down when the cards view is present, and moved back up when the cards view is dismissed
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1000)];
    self.contentView.clipsToBounds = YES;
    self.contentView.backgroundColor = COLOR_BACKGROUND_LIGHT_GRAY;
    [self.scrollView addSubview:self.contentView];
    
    [self setupPieChart];
    
    [self setupPriceCharts];
}

- (void)setAssetType:(AssetType)assetType
{
    _assetType = assetType;
    
    [self reload];
}

- (void)setupPieChart
{
    CGFloat horizontalPadding = DASHBOARD_HORIZONTAL_PADDING;

    UILabel *balancesLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalPadding, 16, self.view.frame.size.width/2, 40)];
    balancesLabel.textColor = COLOR_BLOCKCHAIN_BLUE;
    balancesLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_LARGE];
    balancesLabel.text = [BC_STRING_BALANCES uppercaseString];
    [self.contentView addSubview:balancesLabel];
    
    self.balancesChartView = [[BCBalancesChartView alloc] initWithFrame:CGRectMake(horizontalPadding, balancesLabel.frame.origin.y + balancesLabel.frame.size.height, self.view.frame.size.width - horizontalPadding*2, 320)];
    self.balancesChartView.layer.masksToBounds = NO;
    self.balancesChartView.layer.shadowOffset = CGSizeMake(0, 2);
    self.balancesChartView.layer.shadowRadius = 3;
    self.balancesChartView.layer.shadowOpacity = 0.25;
    [self.contentView addSubview:self.balancesChartView];
}

- (void)setupPriceCharts
{
    CGFloat horizontalPadding = DASHBOARD_HORIZONTAL_PADDING;
    
    UILabel *balancesLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalPadding, self.balancesChartView.frame.origin.y + self.balancesChartView.frame.size.height + 16, self.view.frame.size.width/2, 40)];
    balancesLabel.textColor = COLOR_BLOCKCHAIN_BLUE;
    balancesLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_LARGE];
    balancesLabel.text = [BC_STRING_PRICE_CHARTS uppercaseString];
    [self.contentView addSubview:balancesLabel];
    
    CGSize shadowOffset = CGSizeMake(0, 2);
    CGFloat shadowRadius = 3;
    float shadowOpacity = 0.25;
    
    BCPricePreviewView *bitcoinPreviewView = [[BCPricePreviewView alloc] initWithFrame:CGRectMake(horizontalPadding, balancesLabel.frame.origin.y + balancesLabel.frame.size.height, self.view.frame.size.width - horizontalPadding*2, 140) assetName:BC_STRING_BITCOIN price:@"8000"];
    bitcoinPreviewView.layer.masksToBounds = NO;
    bitcoinPreviewView.layer.shadowOffset = shadowOffset;
    bitcoinPreviewView.layer.shadowRadius = shadowRadius;
    bitcoinPreviewView.layer.shadowOpacity = shadowOpacity;
    [self.contentView addSubview:bitcoinPreviewView];
    
    UITapGestureRecognizer *bitcoinChartTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bitcoinChartTapped)];
    [bitcoinPreviewView addGestureRecognizer:bitcoinChartTapGesture];
    
    BCPricePreviewView *etherPreviewView = [[BCPricePreviewView alloc] initWithFrame:CGRectMake(horizontalPadding, bitcoinPreviewView.frame.origin.y + bitcoinPreviewView.frame.size.height + 16, self.view.frame.size.width - horizontalPadding*2, 140) assetName:BC_STRING_ETHER price:@"1000"];
    etherPreviewView.layer.masksToBounds = NO;
    etherPreviewView.layer.shadowOffset = shadowOffset;
    etherPreviewView.layer.shadowRadius = shadowRadius;
    etherPreviewView.layer.shadowOpacity = shadowOpacity;
    [self.contentView addSubview:etherPreviewView];
    
    UITapGestureRecognizer *etherChartTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(etherChartTapped)];
    [etherPreviewView addGestureRecognizer:etherChartTapGesture];
    
    BCPricePreviewView *bitcoinCashPreviewView = [[BCPricePreviewView alloc] initWithFrame:CGRectMake(horizontalPadding, etherPreviewView.frame.origin.y + etherPreviewView.frame.size.height + 16, self.view.frame.size.width - horizontalPadding*2, 140) assetName:BC_STRING_BITCOIN_CASH price:@"5000"];
    bitcoinCashPreviewView.layer.masksToBounds = NO;
    bitcoinCashPreviewView.layer.shadowOffset = shadowOffset;
    bitcoinCashPreviewView.layer.shadowRadius = shadowRadius;
    bitcoinCashPreviewView.layer.shadowOpacity = shadowOpacity;
    [self.contentView addSubview:bitcoinCashPreviewView];
    
    UITapGestureRecognizer *bitcoinCashChartTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(bitcoinCashChartTapped)];
    [bitcoinCashPreviewView addGestureRecognizer:bitcoinCashChartTapGesture];
}

- (void)reload
{
    [self.balancesChartView updateBitcoinBalance:0];
    [self.balancesChartView updateEtherBalance:@""];
    [self.balancesChartView updateBitcoinCashBalance:0];
    [self.balancesChartView updateChart];

    [self reloadCards];
}

- (void)fetchChartData
{
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_GRAPH_TIME_FRAME];
    GraphTimeFrame *timeFrame = [NSKeyedUnarchiver unarchiveObjectWithData:data] ? : [GraphTimeFrame timeFrameWeek];
    NSInteger startDate;
    NSString *scale = timeFrame.scale;
        
    NSString *base;
    
    if (self.assetType == AssetTypeBitcoin) {
        base = [CURRENCY_SYMBOL_BTC lowercaseString];
        startDate = timeFrame.timeFrame == TimeFrameAll ? [timeFrame startDateBitcoin] : timeFrame.startDate;
    } else {
        base = [CURRENCY_SYMBOL_ETH lowercaseString];
        startDate = timeFrame.timeFrame == TimeFrameAll ? [timeFrame startDateEther] : timeFrame.startDate;
    }
    
    NSString *quote = [NSNumberFormatter localCurrencyCode];
    
    if (!quote) {
        [self showError:BC_STRING_ERROR_CHARTS];
        return;
    }
    
    NSURL *URL = [NSURL URLWithString:[URL_API stringByAppendingString:[NSString stringWithFormat:CHARTS_URL_SUFFIX_ARGUMENTS_BASE_QUOTE_START_SCALE, base, quote, [NSString stringWithFormat:@"%lu", startDate], scale]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDataTask *task = [[SessionManager sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            DLog(@"Error getting chart data - %@", [error localizedDescription]);
            [self showError:[error localizedDescription]];
        } else {
            NSError *jsonError;
            NSArray *values = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            if (jsonError || !values) {
                [self showError:BC_STRING_ERROR_CHARTS];
            } else {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if ([values count] == 0) {
                        [self.chartContainerViewController clearChart];
                        [self showError:BC_STRING_ERROR_CHARTS];
                    } else {
                        [self.chartContainerViewController updateChartWithValues:values];
                    }
                });
            }
        }
    }];
    
    [task resume];
}

- (void)updateEthExchangeRate:(NSDecimalNumber *)rate
{
//    [self.priceChartView updateEthExchangeRate:rate];
}

- (void)bitcoinChartTapped
{
    self.chartContainerViewController = [[BCPriceChartContainerViewController alloc] init];
    self.chartContainerViewController.modalPresentationStyle = UIModalPresentationOverCurrentContext;
    [app.tabControllerManager.tabViewController presentViewController:self.chartContainerViewController animated:YES completion:nil];
    
    BCPriceChartView *priceChartView = [[BCPriceChartView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height*3/4) assetType:AssetTypeBitcoin dataPoints:nil delegate:self];
    [self.chartContainerViewController addPriceChartView:priceChartView];
    
    [self fetchChartData];
}

- (void)etherChartTapped
{
    CGFloat horizontalPadding = DASHBOARD_HORIZONTAL_PADDING;

    BCPriceChartView *priceChartView = [[BCPriceChartView alloc] initWithFrame:CGRectMake(horizontalPadding, 0, self.view.frame.size.width - horizontalPadding, self.view.frame.size.height*2/3) assetType:AssetTypeEther dataPoints:nil delegate:self];
}

- (void)bitcoinCashChartTapped
{
    CGFloat horizontalPadding = DASHBOARD_HORIZONTAL_PADDING;
    
    BCPriceChartView *priceChartView = [[BCPriceChartView alloc] initWithFrame:CGRectMake(horizontalPadding, 0, self.view.frame.size.width - horizontalPadding, self.view.frame.size.height*2/3) assetType:AssetTypeBitcoinCash dataPoints:nil delegate:self];
}

#pragma mark - View Helpers

- (void)showError:(NSString *)error
{
    if ([app isPinSet] &&
        !app.pinEntryViewController &&
        [app.wallet isInitialized] &&
        app.tabControllerManager.tabViewController.selectedIndex == TAB_DASHBOARD
        && !app.modalView) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:error preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.view.window.rootViewController presentViewController:alert animated:YES completion:nil];
        });
    }
}

#pragma mark - Text Helpers

- (NSString *)stringForValue:(double)value axis:(ChartAxisBase *)axis
{
    if (axis == [self.chartContainerViewController leftAxis]) {
        return [NSString stringWithFormat:@"%@%.f", app.latestResponse.symbol_local.symbol, value];
    } else if (axis == [self.chartContainerViewController xAxis]) {
        return [self dateStringFromGraphValue:value];
    } else {
        DLog(@"Warning: no axis found!");
        return nil;
    }
}

- (NSString *)dateStringFromGraphValue:(double)value
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = [self getDateFormat];
    return [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:value]];
}

- (NSString *)getDateFormat
{
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_GRAPH_TIME_FRAME];
    GraphTimeFrame *timeFrame = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    return timeFrame.dateFormat;
}

#pragma mark - Chart View Delegate

- (void)chartValueNothingSelected:(ChartViewBase *)chartView
{
    [self.chartContainerViewController updateTitleContainer];
}

- (void)chartValueSelected:(ChartViewBase *)chartView entry:(ChartDataEntry *)entry highlight:(ChartHighlight *)highlight
{
    [self.chartContainerViewController updateTitleContainerWithChartDataEntry:entry];
}

#pragma mark - BCPriceChartView Delegate

- (void)reloadPriceChartView
{
    [self fetchChartData];
}

@end

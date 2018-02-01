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

@import Charts;

@interface CardsViewController ()
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *contentView;
@end

@interface DashboardViewController () <IChartAxisValueFormatter, ChartViewDelegate, BCPriceChartViewDelegate>
@property (nonatomic) BCPriceChartView *chartView;
@end

@implementation DashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This contentView can be any custom view - intended to be placed at the top of the scroll view, moved down when the cards view is present, and moved back up when the cards view is dismissed
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 320)];
    self.contentView.clipsToBounds = YES;
    self.contentView.backgroundColor = [UIColor whiteColor];
    [self.scrollView addSubview:self.contentView];
}

- (void)setAssetType:(AssetType)assetType
{
    _assetType = assetType;
    
    [self reload];
}

- (void)reload
{
    [self reloadCards];
    
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
                        [self.chartView clear];
                        [self showError:BC_STRING_ERROR_CHARTS];
                    } else {
                        [self.chartView updateWithValues:values];
                    }
                });
            }
        }
    }];
    
    [task resume];
}

- (void)updateEthExchangeRate:(NSDecimalNumber *)rate
{
    [self.chartView updateEthExchangeRate:rate];
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
    if (axis == [self.chartView leftAxis]) {
        return [NSString stringWithFormat:@"%@%.f", app.latestResponse.symbol_local.symbol, value];
    } else if (axis == [self.chartView xAxis]) {
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
    [self.chartView updateTitleContainer];
}

- (void)chartValueSelected:(ChartViewBase *)chartView entry:(ChartDataEntry *)entry highlight:(ChartHighlight *)highlight
{
    [self.chartView updateTitleContainerWithChartDataEntry:entry];
}

#pragma mark - BCPriceChartView Delegate

- (void)reloadPriceChartView
{
    [self reload];
}

@end

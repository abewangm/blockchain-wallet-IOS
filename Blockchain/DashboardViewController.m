//
//  DashboardViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/23/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#define USER_DEFAULTS_KEY_GRAPH_TIME_FRAME @"timeFrame"

#define X_INSET_GRAPH_CONTAINER 16

#import "DashboardViewController.h"
#import "SessionManager.h"
#import "UIView+ChangeFrameAttribute.h"
#import "NSNumberFormatter+Currencies.h"
#import "RootService.h"
#import "GraphTimeFrame.h"

@import Charts;

@interface CardsViewController ()
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *contentView;
@end

@interface DashboardViewController () <IChartAxisValueFormatter>
@property (nonatomic) LineChartView *chartView;
@property (nonatomic) UIView *graphContainerView;
@property (nonatomic) UILabel *titleLabel;

@property (nonatomic) UIView *priceContainerView;
@property (nonatomic) UILabel *priceLabel;
@property (nonatomic) UILabel *percentageChangeLabel;
@property (nonatomic) UIImageView *arrowImageView;

@property (nonatomic) UIButton *allTimeButton;
@property (nonatomic) UIButton *yearButton;
@property (nonatomic) UIButton *monthButton;
@property (nonatomic) UIButton *weekButton;
@property (nonatomic) UIButton *dayButton;
@property (nonatomic) NSString *lastEthExchangeRate;

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
    
    UIView *titleContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 16, self.view.frame.size.width, 60)];
    titleContainerView.backgroundColor = [UIColor clearColor];
    titleContainerView.center = CGPointMake(self.contentView.center.x, titleContainerView.center.y);
    
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    titleLabel.textColor = COLOR_BLOCKCHAIN_BLUE;
    titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_EXTRALIGHT size:FONT_SIZE_EXTRA_SMALL];
    [titleContainerView addSubview:titleLabel];
    self.titleLabel = titleLabel;
    
    self.priceContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    self.priceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.priceLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_LARGE];
    self.priceLabel.textColor = COLOR_BLOCKCHAIN_BLUE;
    [self.priceContainerView addSubview:self.priceLabel];
    
    self.percentageChangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    self.percentageChangeLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
    self.percentageChangeLabel.textColor = COLOR_BLOCKCHAIN_BLUE;
    [self.priceContainerView addSubview:self.percentageChangeLabel];
    
    self.arrowImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 20, 15)];
    self.arrowImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.priceContainerView addSubview:self.arrowImageView];
    
    [titleContainerView addSubview:self.priceContainerView];
    
    [self.contentView addSubview:titleContainerView];
    
    UIView *graphContainerView = [[UIView alloc] initWithFrame:CGRectInset(self.contentView.bounds, X_INSET_GRAPH_CONTAINER, titleContainerView.frame.origin.y + 60)];
    [graphContainerView changeWidth:self.contentView.frame.size.width - graphContainerView.frame.origin.x - 30];
    [graphContainerView changeHeight:self.contentView.frame.size.height - 120];
    
    CGFloat verticalSpacing = 0;
    CGFloat horizontalSpacing = 0;

    LineChartView *chartView = [[LineChartView alloc] initWithFrame:CGRectMake(horizontalSpacing, verticalSpacing, graphContainerView.bounds.size.width - horizontalSpacing*2, graphContainerView.bounds.size.height - verticalSpacing*2)];
    chartView.drawGridBackgroundEnabled = NO;
    chartView.drawBordersEnabled = NO;
    chartView.scaleXEnabled = NO;
    chartView.scaleYEnabled = NO;
    chartView.pinchZoomEnabled = NO;
    chartView.doubleTapToZoomEnabled = NO;
    chartView.chartDescription.enabled = NO;
    chartView.legend.enabled = NO;
    
    chartView.leftAxis.drawGridLinesEnabled = NO;
    chartView.leftAxis.labelTextColor = COLOR_TEXT_GRAY;
    chartView.leftAxis.labelFont = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_EXTRA_EXTRA_SMALL];
    chartView.leftAxis.labelCount = 4;
    
    chartView.rightAxis.enabled = NO;
    
    chartView.xAxis.labelFont = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_EXTRA_EXTRA_SMALL];
    chartView.xAxis.drawGridLinesEnabled = NO;
    chartView.xAxis.labelTextColor = COLOR_TEXT_GRAY;
    chartView.xAxis.labelPosition = XAxisLabelPositionBottom;
    chartView.xAxis.granularityEnabled = YES;
    chartView.xAxis.labelCount = 4;
    [chartView setExtraOffsetsWithLeft:8.0 top:0 right:0 bottom:10.0];
    chartView.noDataFont = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_EXTRA_EXTRA_SMALL];
    chartView.noDataTextColor = COLOR_TEXT_GRAY;
    
    chartView.xAxis.valueFormatter = self;
    chartView.leftAxis.valueFormatter = self;

    self.chartView = chartView;
    [graphContainerView addSubview:self.chartView];
    
    [self.contentView addSubview:graphContainerView];
    self.graphContainerView = graphContainerView;
    
    [self setupTimeSpanButtons];
    
    NSData *data = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_GRAPH_TIME_FRAME];
    GraphTimeFrame *timeFrame = [NSKeyedUnarchiver unarchiveObjectWithData:data];
    
    UIButton *selectedButton;
    
    [self.weekButton setSelected:NO];
    [self.monthButton setSelected:NO];
    [self.yearButton setSelected:NO];
    [self.allTimeButton setSelected:NO];
    
    if (!timeFrame || timeFrame.timeFrame == TimeFrameWeek) {
        selectedButton = self.weekButton;
    } else if (timeFrame.timeFrame == TimeFrameMonth) {
        selectedButton = self.monthButton;
    } else if (timeFrame.timeFrame == TimeFrameYear) {
        selectedButton = self.yearButton;
    } else if (timeFrame.timeFrame == TimeFrameAll) {
        selectedButton = self.allTimeButton;
    } else if (timeFrame.timeFrame == TimeFrameDay) {
        selectedButton = self.dayButton;
    }

    [selectedButton setSelected:YES];
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
                    [self updateTitleContainer:values];
                    [self setChartValues:values];
                });
            }
        }
    }];
    
    [task resume];
}

- (void)updateTitleContainer:(NSArray *)values
{
    self.titleLabel.text = self.assetType == AssetTypeBitcoin ? [BC_STRING_BITCOIN_PRICE uppercaseString] : [BC_STRING_ETHER_PRICE uppercaseString];
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake([self.titleLabel superview].frame.size.width/2, self.titleLabel.center.y);
    
    self.priceLabel.text = self.assetType == AssetTypeBitcoin ? [NSNumberFormatter formatMoney:SATOSHI localCurrency:YES] : self.lastEthExchangeRate;
    [self.priceLabel sizeToFit];
    
    double firstPrice = [[[values firstObject] objectForKey:DICTIONARY_KEY_PRICE] doubleValue];
    double lastPrice = [[[values lastObject] objectForKey:DICTIONARY_KEY_PRICE] doubleValue];
    double difference = lastPrice - firstPrice;
    double percentChange = (difference / firstPrice) * 100;
    
    self.arrowImageView.image = [[UIImage imageNamed:@"send_arrow"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    self.arrowImageView.tintColor = COLOR_BLOCKCHAIN_GREEN;
    [self.arrowImageView changeXPosition:self.priceLabel.frame.size.width + 8];
    [self.arrowImageView changeYPosition:self.priceLabel.frame.size.height - self.arrowImageView.frame.size.height - 3.5];
 
    UIImage *arrowImage = [UIImage imageNamed:@"down_triangle"];
    
    if (percentChange > 0) {
        self.arrowImageView.image = [[UIImage imageWithCGImage:arrowImage.CGImage scale:1.0f orientation:UIImageOrientationDownMirrored] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.arrowImageView.tintColor = COLOR_BLOCKCHAIN_GREEN;
    } else {
        self.arrowImageView.image = [arrowImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        self.arrowImageView.tintColor = COLOR_BLOCKCHAIN_RED;
    }
    
    self.percentageChangeLabel.text = [NSString stringWithFormat:@"%.1f%%", percentChange];
    [self.percentageChangeLabel sizeToFit];
    [self.percentageChangeLabel changeYPosition:self.priceLabel.frame.size.height - self.percentageChangeLabel.frame.size.height - 1.5];
    [self.percentageChangeLabel changeXPosition:self.priceLabel.frame.origin.x + self.priceLabel.frame.size.width + 8 + self.arrowImageView.frame.size.width];
    
    self.priceContainerView.frame = CGRectMake(0, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height, self.priceLabel.frame.size.width + 8 + self.arrowImageView.frame.size.width + self.percentageChangeLabel.frame.size.width, 30);
    self.priceContainerView.center = CGPointMake(self.contentView.center.x, self.priceContainerView.center.y);
}

- (void)setChartValues:(NSArray *)values
{
    NSMutableArray *finalValues = [NSMutableArray new];

    for (NSDictionary *dict in values) {
        double x = [[dict objectForKey:DICTIONARY_KEY_TIMESTAMP] doubleValue];
        double y = [[dict objectForKey:DICTIONARY_KEY_PRICE] doubleValue];
        ChartDataEntry *value = [[ChartDataEntry alloc] initWithX:x y:y];
        [finalValues addObject:value];
    }
    
    LineChartDataSet *dataSet = [[LineChartDataSet alloc] initWithValues:finalValues label:nil];
    dataSet.lineWidth = 1.5f;
    dataSet.colors = @[COLOR_BLOCKCHAIN_BLUE];
    dataSet.mode = LineChartModeLinear;
    dataSet.drawValuesEnabled = NO;
    dataSet.circleRadius = 1.0f;
    dataSet.drawCircleHoleEnabled = NO;
    dataSet.circleColors = @[COLOR_BLOCKCHAIN_BLUE];
    dataSet.drawFilledEnabled = NO;
    dataSet.highlightEnabled = NO;
    dataSet.drawVerticalHighlightIndicatorEnabled = NO;
    dataSet.drawHorizontalHighlightIndicatorEnabled = NO;
    self.chartView.data = [[LineChartData alloc] initWithDataSet:dataSet];
}

- (void)setupTimeSpanButtons
{
    CGFloat buttonContainerViewWidth = 280;
    UIView *buttonContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.graphContainerView.frame.origin.y + self.graphContainerView.frame.size.height + 16, buttonContainerViewWidth, 30)];
    
    CGFloat buttonWidth = buttonContainerViewWidth/5;
    
    self.allTimeButton = [self timeSpanButtonWithFrame:CGRectMake(0, 0, buttonWidth, 30) title:BC_STRING_ALL];
    [buttonContainerView addSubview:self.allTimeButton];

    self.yearButton = [self timeSpanButtonWithFrame:CGRectMake(self.allTimeButton.frame.origin.x + self.allTimeButton.frame.size.width, 0, buttonWidth, 30) title:BC_STRING_YEAR];
    [buttonContainerView addSubview:self.yearButton];
    
    self.monthButton = [self timeSpanButtonWithFrame:CGRectMake(self.yearButton.frame.origin.x + self.yearButton.frame.size.width, 0, buttonWidth, 30) title:BC_STRING_MONTH];
    [buttonContainerView addSubview:self.monthButton];
    
    self.weekButton = [self timeSpanButtonWithFrame:CGRectMake(self.monthButton.frame.origin.x + self.monthButton.frame.size.width, 0, buttonWidth, 30) title:BC_STRING_WEEK];
    [buttonContainerView addSubview:self.weekButton];
    
    self.dayButton = [self timeSpanButtonWithFrame:CGRectMake(self.weekButton.frame.origin.x + self.weekButton.frame.size.width, 0, buttonWidth, 30) title:BC_STRING_DAY];
    [buttonContainerView addSubview:self.dayButton];
    
    [self.contentView addSubview:buttonContainerView];
    buttonContainerView.center = CGPointMake(self.graphContainerView.center.x + 20, buttonContainerView.center.y);
}

- (void)timeSpanButtonTapped:(UIButton *)button
{
    [self.weekButton setSelected:NO];
    [self.monthButton setSelected:NO];
    [self.yearButton setSelected:NO];
    [self.dayButton setSelected:NO];
    [self.allTimeButton setSelected:NO];

    [button setSelected:YES];
    
    GraphTimeFrame *timeFrame;
    
    if (button == self.dayButton) {
        timeFrame = [GraphTimeFrame timeFrameDay];
    } else if (button == self.weekButton) {
        timeFrame = [GraphTimeFrame timeFrameWeek];
    } else if (button == self.monthButton) {
        timeFrame = [GraphTimeFrame timeFrameMonth];
    } else if (button == self.yearButton) {
        timeFrame = [GraphTimeFrame timeFrameYear];
    } else {
        timeFrame = [GraphTimeFrame timeFrameAll:self.assetType];
    }
    
    NSUserDefaults *currentDefaults = [NSUserDefaults standardUserDefaults];
    NSData *data = [NSKeyedArchiver archivedDataWithRootObject:timeFrame];
    [currentDefaults setObject:data forKey:USER_DEFAULTS_KEY_GRAPH_TIME_FRAME];
    
    [self reload];
}

- (void)updateEthExchangeRate:(NSDecimalNumber *)rate
{
    self.lastEthExchangeRate = [NSNumberFormatter formatEthToFiatWithSymbol:@"1" exchangeRate:rate];
    [self reload];
}

#pragma mark - View Helpers

- (UIButton *)timeSpanButtonWithFrame:(CGRect)frame title:(NSString *)title
{
    UIFont *normalFont = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
    UIFont *selectedFont = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
    
    NSAttributedString *attrNormal = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName:normalFont, NSForegroundColorAttributeName:COLOR_BLOCKCHAIN_BLUE, NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleNone]}];
    NSAttributedString *attrSelected = [[NSAttributedString alloc] initWithString:title attributes:@{NSFontAttributeName:selectedFont, NSForegroundColorAttributeName:COLOR_BLOCKCHAIN_BLUE, NSUnderlineStyleAttributeName:[NSNumber numberWithInt:NSUnderlineStyleSingle]}];
    
    UIButton *button = [[UIButton alloc] initWithFrame:frame];
    [button setAttributedTitle:attrNormal forState:UIControlStateNormal];
    [button setAttributedTitle:attrSelected forState:UIControlStateSelected];
    [button addTarget:self action:@selector(timeSpanButtonTapped:) forControlEvents:UIControlEventTouchUpInside];
    
    UIButton *testButton = [UIButton new];
    [testButton setTitle:title forState:UIControlStateNormal];
    [testButton sizeToFit];
    
    [button changeWidth:testButton.frame.size.width];
    [button changeXPosition:frame.origin.x + 8];
    return button;
}

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
    if (axis == self.chartView.leftAxis) {
        return [NSString stringWithFormat:@"%@%.f", app.latestResponse.symbol_local.symbol, value];
    } else if (axis == self.chartView.xAxis) {
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

@end

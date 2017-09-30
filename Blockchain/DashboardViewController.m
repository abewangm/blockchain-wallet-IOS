//
//  DashboardViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/23/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#define USER_DEFAULTS_KEY_GRAPH_TIME_FRAME @"graphTimeFrame"

#define ENTRY_TIME_BTC 1282089600
#define ENTRY_TIME_ETH 1438992000

#define GRAPH_TIME_FRAME_DAY @"1day"
#define GRAPH_TIME_FRAME_WEEK @"1weeks"
#define GRAPH_TIME_FRAME_MONTH @"4weeks"
#define GRAPH_TIME_FRAME_YEAR @"52weeks"
#define GRAPH_TIME_FRAME_ALL @"all"

#define TIME_INTERVAL_DAY 86400.0
#define TIME_INTERVAL_WEEK 604800.0
#define TIME_INTERVAL_MONTH 2592000.0
#define TIME_INTERVAL_YEAR 31536000.0

#define STRING_SCALE_FIVE_DAYS @"432000"
#define STRING_SCALE_ONE_DAY @"86400"
#define STRING_SCALE_TWO_HOURS @"7200"
#define STRING_SCALE_ONE_HOUR @"3600"
#define STRING_SCALE_FIFTEEN_MINUTES @"900"

#define X_INSET_GRAPH_CONTAINER 80

#import "DashboardViewController.h"
#import "SessionManager.h"
#import "BCPriceGraphView.h"
#import "UIView+ChangeFrameAttribute.h"
#import "NSNumberFormatter+Currencies.h"
#import "RootService.h"

@interface CardsViewController ()
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *contentView;
@end

@interface DashboardViewController ()
@property (nonatomic) UIView *graphContainerView;
@property (nonatomic) BCPriceGraphView *graphView;
@property (nonatomic) UILabel *priceLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *allTimeButton;
@property (nonatomic) UIButton *yearButton;
@property (nonatomic) UIButton *monthButton;
@property (nonatomic) UIButton *weekButton;
@property (nonatomic) UIButton *dayButton;
@property (nonatomic) NSString *lastEthExchangeRate;

// X axis
@property (nonatomic) UILabel *xAxisLabelFirst;
@property (nonatomic) UILabel *xAxisLabelSecond;
@property (nonatomic) UILabel *xAxisLabelThird;
@property (nonatomic) UILabel *xAxisLabelFourth;

// Y axis
@property (nonatomic) UILabel *yAxisLabelFirst;
@property (nonatomic) UILabel *yAxisLabelSecond;
@property (nonatomic) UILabel *yAxisLabelThird;

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
    
    self.priceLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.priceLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_LARGE];
    self.priceLabel.textColor = COLOR_BLOCKCHAIN_BLUE;
    [titleContainerView addSubview:self.priceLabel];
    
    [self.contentView addSubview:titleContainerView];
    
    UIView *graphContainerView = [[UIView alloc] initWithFrame:CGRectInset(self.contentView.bounds, X_INSET_GRAPH_CONTAINER, titleContainerView.frame.origin.y + 60)];
    [graphContainerView changeWidth:self.contentView.frame.size.width - graphContainerView.frame.origin.x - 30];
    [graphContainerView changeHeight:self.contentView.frame.size.height - 150];
    
    CGFloat verticalSpacing = 0;
    CGFloat horizontalSpacing = 0;

    self.graphView = [[BCPriceGraphView alloc] initWithFrame:CGRectMake(horizontalSpacing, verticalSpacing, graphContainerView.bounds.size.width - horizontalSpacing*2, graphContainerView.bounds.size.height - verticalSpacing*2)];
    self.graphView.backgroundColor = [UIColor whiteColor];
    [graphContainerView addSubview:self.graphView];
    
    [self.contentView addSubview:graphContainerView];
    self.graphContainerView = graphContainerView;
    
    UIView *verticalBorder = [[UIView alloc] initWithFrame:CGRectMake(graphContainerView.frame.origin.x - 1, graphContainerView.frame.origin.y, 1, graphContainerView.frame.size.height + 1)];
    verticalBorder.backgroundColor = COLOR_LIGHT_GRAY;
    [self.contentView addSubview:verticalBorder];
    
    UIView *horizontalBorder = [[UIView alloc] initWithFrame:CGRectMake(graphContainerView.frame.origin.x, graphContainerView.frame.origin.y + graphContainerView.frame.size.height, graphContainerView.frame.size.width, 1)];
    horizontalBorder.backgroundColor = COLOR_LIGHT_GRAY;
    [self.contentView addSubview:horizontalBorder];
    
    [self setupAxes];
    
    [self setupTimeSpanButtons];
    
    NSString *timeFrame = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_GRAPH_TIME_FRAME];
    
    UIButton *selectedButton;
    
    [self.weekButton setSelected:NO];
    [self.monthButton setSelected:NO];
    [self.yearButton setSelected:NO];
    [self.allTimeButton setSelected:NO];
    
    if (!timeFrame || [timeFrame isEqualToString:GRAPH_TIME_FRAME_WEEK]) {
        selectedButton = self.weekButton;
    } else if ([timeFrame isEqualToString:GRAPH_TIME_FRAME_MONTH]) {
        selectedButton = self.monthButton;
    } else if ([timeFrame isEqualToString:GRAPH_TIME_FRAME_YEAR]) {
        selectedButton = self.yearButton;
    } else if ([timeFrame isEqualToString:GRAPH_TIME_FRAME_ALL]) {
        selectedButton = self.allTimeButton;
    } else if ([timeFrame isEqualToString:GRAPH_TIME_FRAME_DAY]) {
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
    self.titleLabel.text = self.assetType == AssetTypeBitcoin ? [BC_STRING_BITCOIN_PRICE uppercaseString] : [BC_STRING_ETHER_PRICE uppercaseString];
    [self.titleLabel sizeToFit];
    self.titleLabel.center = CGPointMake([self.titleLabel superview].frame.size.width/2, self.titleLabel.center.y);
    
    self.priceLabel.text = self.assetType == AssetTypeBitcoin ? [NSNumberFormatter formatMoney:SATOSHI localCurrency:YES] : self.lastEthExchangeRate;
    self.priceLabel.frame = CGRectMake(0, self.titleLabel.frame.origin.y + self.titleLabel.frame.size.height, 0, 0);
    [self.priceLabel sizeToFit];
    self.priceLabel.center = CGPointMake(self.contentView.center.x, self.priceLabel.center.y);
    
    [self reloadCards];
    
    NSString *timeSpan = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_GRAPH_TIME_FRAME] ? : GRAPH_TIME_FRAME_WEEK;
    NSDate *today = [NSDate date];
    NSInteger startDate = 0;
    NSString *scale;
    
    if ([timeSpan isEqualToString:GRAPH_TIME_FRAME_DAY]) {
        scale = STRING_SCALE_FIFTEEN_MINUTES;
        startDate = (NSInteger)fabs([[today dateByAddingTimeInterval:-TIME_INTERVAL_DAY] timeIntervalSince1970]);
    } else if ([timeSpan isEqualToString:GRAPH_TIME_FRAME_WEEK]) {
        scale = STRING_SCALE_ONE_HOUR;
        startDate = (NSInteger)fabs([[today dateByAddingTimeInterval:-TIME_INTERVAL_WEEK] timeIntervalSince1970]);
    } else if ([timeSpan isEqualToString:GRAPH_TIME_FRAME_MONTH]) {
        scale = STRING_SCALE_TWO_HOURS;
        startDate = (NSInteger)fabs([[today dateByAddingTimeInterval:-TIME_INTERVAL_MONTH] timeIntervalSince1970]);
    } else if ([timeSpan isEqualToString:GRAPH_TIME_FRAME_YEAR]) {
        scale = STRING_SCALE_ONE_DAY;
        startDate = (NSInteger)fabs([[today dateByAddingTimeInterval:-TIME_INTERVAL_YEAR] timeIntervalSince1970]);
    } else if ([timeSpan isEqualToString:GRAPH_TIME_FRAME_ALL]) {
        scale = STRING_SCALE_FIVE_DAYS;
        if (self.assetType == AssetTypeBitcoin) {
            startDate = ENTRY_TIME_BTC;
        } else if (self.assetType == AssetTypeEther) {
            startDate = ENTRY_TIME_ETH;
        }
    }
        
    NSString *base;
    
    if (self.assetType == AssetTypeBitcoin) {
        base = [CURRENCY_SYMBOL_BTC lowercaseString];
    } else {
        base = [CURRENCY_SYMBOL_ETH lowercaseString];
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
                    [self.graphView setGraphValues:values];
                    [self updateAxisLabelsWithGraphValues:values];
                });
            }
        }
    }];
    
    [task resume];
}

- (void)setupAxes
{
    [self setupXAxis];
    [self setupYAxis];
}

- (void)setupXAxis
{
    UIView *labelContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.graphContainerView.frame.origin.x, self.graphContainerView.frame.origin.y + self.graphContainerView.frame.size.height + 8, self.graphContainerView.frame.size.width, 30)];
    labelContainerView.backgroundColor = [UIColor clearColor];
    
    UILabel *firstLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    firstLabel.center = CGPointMake(labelContainerView.frame.size.width/8, labelContainerView.frame.size.height/2);
    [labelContainerView addSubview:firstLabel];
    
    UILabel *secondLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    secondLabel.center = CGPointMake(labelContainerView.frame.size.width/2 - labelContainerView.frame.size.width/8, labelContainerView.frame.size.height/2);
    [labelContainerView addSubview:secondLabel];
    
    UILabel *thirdLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    thirdLabel.center = CGPointMake(labelContainerView.frame.size.width/2 + labelContainerView.frame.size.width/8, labelContainerView.frame.size.height/2);
    [labelContainerView addSubview:thirdLabel];
    
    UILabel *fourthLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    fourthLabel.center = CGPointMake(labelContainerView.frame.size.width*7/8, labelContainerView.frame.size.height/2);
    [labelContainerView addSubview:fourthLabel];
    
    [self.contentView addSubview:labelContainerView];
    
    self.xAxisLabelFirst = firstLabel;
    self.xAxisLabelSecond = secondLabel;
    self.xAxisLabelThird = thirdLabel;
    self.xAxisLabelFourth = fourthLabel;
}

- (void)setupYAxis
{
    UIView *labelContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.graphContainerView.frame.origin.x - X_INSET_GRAPH_CONTAINER, self.graphContainerView.frame.origin.y, X_INSET_GRAPH_CONTAINER, self.graphContainerView.frame.size.height)];
    labelContainerView.backgroundColor = [UIColor clearColor];
    
    UILabel *firstLabel = [self axisLabelWithFrame:CGRectMake(0, 0, labelContainerView.frame.size.width, 30)];
    firstLabel.center = CGPointMake(labelContainerView.frame.size.width/2, labelContainerView.frame.size.height*3/4);
    [labelContainerView addSubview:firstLabel];
    
    UILabel *secondLabel = [self axisLabelWithFrame:CGRectMake(0, 0, labelContainerView.frame.size.width, 30)];
    secondLabel.center = CGPointMake(labelContainerView.frame.size.width/2, labelContainerView.frame.size.height/2);
    [labelContainerView addSubview:secondLabel];

    UILabel *thirdLabel = [self axisLabelWithFrame:CGRectMake(0, 0, labelContainerView.frame.size.width, 30)];
    thirdLabel.center = CGPointMake(labelContainerView.frame.size.width/2, labelContainerView.frame.size.height/4);
    [labelContainerView addSubview:thirdLabel];
    
    [self.contentView addSubview:labelContainerView];
    
    self.yAxisLabelFirst = firstLabel;
    self.yAxisLabelSecond = secondLabel;
    self.yAxisLabelThird = thirdLabel;
}

- (void)setupTimeSpanButtons
{
    CGFloat buttonContainerViewWidth = 280;
    UIView *buttonContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.graphContainerView.frame.origin.y + self.graphContainerView.frame.size.height + 50, buttonContainerViewWidth, 30)];
    
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
    buttonContainerView.center = CGPointMake(self.graphContainerView.center.x, buttonContainerView.center.y);
}

- (void)updateAxisLabelsWithGraphValues:(NSArray *)graphValues
{
    NSUInteger firstTimeIndex = roundf(graphValues.count / 8.0);
    NSUInteger secondTimeIndex = roundf(graphValues.count / 2.0 - graphValues.count / 8.0);
    NSUInteger thirdTimeIndex = roundf(graphValues.count / 2.0 + graphValues.count / 8.0);
    NSUInteger fourthTimeIndex = roundf(graphValues.count * 7.0 / 8.0);

    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MMM dd";
    self.xAxisLabelFirst.text = [self dateStringFromGraphValue:[graphValues objectAtIndex:firstTimeIndex]];
    self.xAxisLabelSecond.text = [self dateStringFromGraphValue:[graphValues objectAtIndex:secondTimeIndex]];
    self.xAxisLabelThird.text = [self dateStringFromGraphValue:[graphValues objectAtIndex:thirdTimeIndex]];
    self.xAxisLabelFourth.text = [self dateStringFromGraphValue:[graphValues objectAtIndex:fourthTimeIndex]];
    
    CGFloat firstPrice = self.graphView.firstQuarter;
    CGFloat secondPrice = self.graphView.secondQuarter;
    CGFloat thirdPrice = self.graphView.thirdQuarter;

    self.yAxisLabelFirst.text = [NSString stringWithFormat:@"%.f", roundf(firstPrice)];
    self.yAxisLabelSecond.text = [NSString stringWithFormat:@"%.f", roundf(secondPrice)];
    self.yAxisLabelThird.text = [NSString stringWithFormat:@"%.f", roundf(thirdPrice)];
}

- (void)timeSpanButtonTapped:(UIButton *)button
{
    [self.weekButton setSelected:NO];
    [self.monthButton setSelected:NO];
    [self.yearButton setSelected:NO];
    [self.dayButton setSelected:NO];
    [self.allTimeButton setSelected:NO];

    [button setSelected:YES];
    
    NSString *timeFrame;
    
    if (button == self.dayButton) {
        timeFrame = GRAPH_TIME_FRAME_DAY;
    } else if (button == self.weekButton) {
        timeFrame = GRAPH_TIME_FRAME_WEEK;
    } else if (button == self.monthButton) {
        timeFrame = GRAPH_TIME_FRAME_MONTH;
    } else if (button == self.yearButton) {
        timeFrame = GRAPH_TIME_FRAME_YEAR;
    } else {
        timeFrame = GRAPH_TIME_FRAME_ALL;
    }
    
    [[NSUserDefaults standardUserDefaults] setObject:timeFrame forKey:USER_DEFAULTS_KEY_GRAPH_TIME_FRAME];
    
    [self reload];
}

- (void)updateEthExchangeRate:(NSDecimalNumber *)rate
{
    self.lastEthExchangeRate = [NSNumberFormatter formatEthToFiatWithSymbol:@"1" exchangeRate:rate];
    [self reload];
}

#pragma mark - View Helpers

- (UILabel *)axisLabelWithFrame:(CGRect)frame
{
    UILabel *label = [[UILabel alloc] initWithFrame:frame];
    label.textAlignment = NSTextAlignmentCenter;
    label.textColor = COLOR_TEXT_DARK_GRAY;
    label.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    return label;
}

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
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:error preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    dispatch_async(dispatch_get_main_queue(), ^{
        if (!app.pinEntryViewController)
        [self.view.window.rootViewController presentViewController:alert animated:YES completion:nil];
    });
}

#pragma mark - Text Helpers

- (NSString *)dateStringFromGraphValue:(NSDictionary *)graphInfo
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MMM dd";
    return [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[graphInfo objectForKey:DICTIONARY_KEY_TIMESTAMP] floatValue]]];
}

@end

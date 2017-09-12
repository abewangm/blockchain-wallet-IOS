//
//  DashboardViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/23/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#define USER_DEFAULTS_KEY_GRAPH_TIME_FRAME @"graphTimeFrame"
#define GRAPH_TIME_FRAME_WEEK @"1weeks"
#define GRAPH_TIME_FRAME_MONTH @"4weeks"
#define GRAPH_TIME_FRAME_YEAR @"52weeks"

#import "DashboardViewController.h"
#import "SessionManager.h"
#import "BCPriceGraphView.h"
#import "UIView+ChangeFrameAttribute.h"
#import "NSNumberFormatter+Currencies.h"

@interface CardsViewController ()
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *contentView;
@end

@interface DashboardViewController ()
@property (nonatomic) BCPriceGraphView *graphView;
@property (nonatomic) UILabel *priceLabel;
@property (nonatomic) UILabel *titleLabel;
@property (nonatomic) UIButton *yearButton;
@property (nonatomic) UIButton *monthButton;
@property (nonatomic) UIButton *weekButton;
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
@property (nonatomic) UILabel *yAxisLabelFourth;

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
    
    UIView *titleContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 60)];
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
    
    self.graphView = [[BCPriceGraphView alloc] initWithFrame:CGRectInset(self.contentView.bounds, 60, 60)];
    self.graphView.backgroundColor = [UIColor whiteColor];
    [self.graphView changeWidth:self.contentView.frame.size.width - self.graphView.frame.origin.x - 30];
    [self.graphView changeHeight:self.contentView.frame.size.height - 150];
    [self.contentView addSubview:self.graphView];
    
    UIView *verticalBorder = [[UIView alloc] initWithFrame:CGRectMake(self.graphView.frame.origin.x - 1, self.graphView.frame.origin.y, 1, self.graphView.frame.size.height + 1)];
    verticalBorder.backgroundColor = COLOR_LIGHT_GRAY;
    [self.contentView addSubview:verticalBorder];
    
    UIView *horizontalBorder = [[UIView alloc] initWithFrame:CGRectMake(self.graphView.frame.origin.x, self.graphView.frame.origin.y + self.graphView.frame.size.height, self.graphView.frame.size.width, 1)];
    horizontalBorder.backgroundColor = COLOR_LIGHT_GRAY;
    [self.contentView addSubview:horizontalBorder];
    
    [self setupAxes];
    
    [self setupTimeSpanButtons];
    
    NSString *timeFrame = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_GRAPH_TIME_FRAME];
    
    UIButton *selectedButton;
    
    [self.weekButton setSelected:NO];
    [self.monthButton setSelected:NO];
    [self.yearButton setSelected:NO];
    
    if (!timeFrame || [timeFrame isEqualToString:GRAPH_TIME_FRAME_WEEK]) {
        selectedButton = self.weekButton;
    } else if ([timeFrame isEqualToString:GRAPH_TIME_FRAME_MONTH]) {
        selectedButton = self.monthButton;
    } else if ([timeFrame isEqualToString:GRAPH_TIME_FRAME_YEAR]) {
        selectedButton = self.yearButton;
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
    
    NSString *timeSpan = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_GRAPH_TIME_FRAME];
    
    NSURL *URL = [NSURL URLWithString:[URL_SERVER stringByAppendingString:[NSString stringWithFormat:CHARTS_URL_SUFFIX_ARGUMENT_TIME_SPAN, timeSpan]]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDataTask *task = [[SessionManager sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            DLog(@"Error getting chart data - %@", [error localizedDescription]);
        } else {
            NSError *jsonError;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
//             DLog(@"%@", jsonResponse);
            
            dispatch_async(dispatch_get_main_queue(), ^{
                NSArray *values = [jsonResponse objectForKey:DICTIONARY_KEY_VALUES];
                [self.graphView setGraphValues:values];
                [self updateAxisLabelsWithGraphValues:values];
            });
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
    UIView *labelContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.graphView.frame.origin.x, self.graphView.frame.origin.y + self.graphView.frame.size.height + 8, self.graphView.frame.size.width, 30)];
    labelContainerView.backgroundColor = [UIColor clearColor];
    
    UILabel *firstLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    firstLabel.text = @"test";
    firstLabel.center = CGPointMake(labelContainerView.frame.size.width/8, labelContainerView.frame.size.height/2);
    [labelContainerView addSubview:firstLabel];
    
    UILabel *secondLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    secondLabel.text = @"test";
    secondLabel.center = CGPointMake(labelContainerView.frame.size.width/2 - labelContainerView.frame.size.width/8, labelContainerView.frame.size.height/2);
    [labelContainerView addSubview:secondLabel];
    
    UILabel *thirdLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    thirdLabel.text = @"test";
    thirdLabel.center = CGPointMake(labelContainerView.frame.size.width/2 + labelContainerView.frame.size.width/8, labelContainerView.frame.size.height/2);
    [labelContainerView addSubview:thirdLabel];
    
    UILabel *fourthLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    fourthLabel.text = @"test";
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
    UIView *labelContainerView = [[UIView alloc] initWithFrame:CGRectMake(self.graphView.frame.origin.x - 60 - 8, self.graphView.frame.origin.y, 60, self.graphView.frame.size.height)];
    labelContainerView.backgroundColor = [UIColor clearColor];
    
    UILabel *firstLabel = [self axisLabelWithFrame:CGRectMake(0, 0, labelContainerView.frame.size.width, 30)];
    firstLabel.text = @"test";
    firstLabel.center = CGPointMake(labelContainerView.frame.size.width/2, labelContainerView.frame.size.height*7/8);
    [labelContainerView addSubview:firstLabel];
    
    UILabel *secondLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    secondLabel.text = @"test";
    secondLabel.center = CGPointMake(labelContainerView.frame.size.width/2, labelContainerView.frame.size.height/2 + labelContainerView.frame.size.height/8);
    [labelContainerView addSubview:secondLabel];

    UILabel *thirdLabel = [self axisLabelWithFrame:CGRectMake(0, 0, 60, labelContainerView.frame.size.height)];
    thirdLabel.text = @"test";
    thirdLabel.center = CGPointMake(labelContainerView.frame.size.width/2, labelContainerView.frame.size.height/2 - labelContainerView.frame.size.height/8);
    [labelContainerView addSubview:thirdLabel];

    UILabel *fourthLabel = [self axisLabelWithFrame:CGRectMake(0, labelContainerView.frame.size.height/8, 60, labelContainerView.frame.size.height)];
    fourthLabel.text = @"test";
    fourthLabel.center = CGPointMake(labelContainerView.frame.size.width/2, labelContainerView.frame.size.height/8);
    [labelContainerView addSubview:fourthLabel];
    
    [self.contentView addSubview:labelContainerView];
    
    self.yAxisLabelFirst = firstLabel;
    self.yAxisLabelSecond = secondLabel;
    self.yAxisLabelThird = thirdLabel;
    self.yAxisLabelFourth = fourthLabel;
}

- (void)setupTimeSpanButtons
{
    CGFloat buttonContainerViewWidth = 210;
    UIView *buttonContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.graphView.frame.origin.y + self.graphView.frame.size.height + 50, buttonContainerViewWidth, 30)];
    
    CGFloat buttonWidth = buttonContainerViewWidth/3;
    
    self.weekButton = [self timeSpanButtonWithFrame:CGRectMake(0, 0, buttonWidth, 30) title:BC_STRING_WEEK];
    [buttonContainerView addSubview:self.weekButton];
    
    self.monthButton = [self timeSpanButtonWithFrame:CGRectMake(self.weekButton.frame.origin.x + buttonWidth, 0, buttonWidth, 30) title:BC_STRING_MONTH];
    [buttonContainerView addSubview:self.monthButton];
    
    self.yearButton = [self timeSpanButtonWithFrame:CGRectMake(self.monthButton.frame.origin.x + buttonWidth, 0, buttonWidth, 30) title:BC_STRING_YEAR];
    [buttonContainerView addSubview:self.yearButton];
    
    [self.contentView addSubview:buttonContainerView];
    buttonContainerView.center = CGPointMake(self.contentView.center.x, buttonContainerView.center.y);
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
    
    CGFloat maxPrice = self.graphView.maxY;
    CGFloat minPrice = self.graphView.minY;
    
    CGFloat median = (maxPrice + minPrice) / 2;
    CGFloat firstQuarter = (median + minPrice) / 2;
    CGFloat lastQuarter = (maxPrice + median) / 2;
    
    CGFloat firstPrice = (firstQuarter + minPrice) / 2;
    CGFloat secondPrice = (median + firstQuarter) / 2;
    CGFloat thirdPrice = (lastQuarter + median) / 2;
    CGFloat fourthPrice = (maxPrice + lastQuarter) / 2;

    self.yAxisLabelFirst.text = [NSString stringWithFormat:@"%.f", roundf(firstPrice)];
    self.yAxisLabelSecond.text = [NSString stringWithFormat:@"%.f", roundf(secondPrice)];
    self.yAxisLabelThird.text = [NSString stringWithFormat:@"%.f", roundf(thirdPrice)];
    self.yAxisLabelFourth.text = [NSString stringWithFormat:@"%.f", roundf(fourthPrice)];
}

- (void)timeSpanButtonTapped:(UIButton *)button
{
    [self.weekButton setSelected:NO];
    [self.monthButton setSelected:NO];
    [self.yearButton setSelected:NO];

    [button setSelected:YES];
    
    NSString *timeFrame;
    
    if (button == self.weekButton) {
        timeFrame = GRAPH_TIME_FRAME_WEEK;
    } else if (button == self.monthButton) {
        timeFrame = GRAPH_TIME_FRAME_MONTH;
    } else if (button == self.yearButton) {
        timeFrame = GRAPH_TIME_FRAME_YEAR;
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
    label.textColor = COLOR_LIGHT_GRAY;
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
    return button;
}

#pragma mark - Text Helpers

- (NSString *)dateStringFromGraphValue:(NSDictionary *)graphInfo
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MMM dd";
    return [dateFormatter stringFromDate:[NSDate dateWithTimeIntervalSince1970:[[graphInfo objectForKey:DICTIONARY_KEY_X] floatValue]]];
}

@end

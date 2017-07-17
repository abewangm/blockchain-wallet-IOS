//
//  BCConfirmPaymentView.m
//  Blockchain
//
//  Created by Kevin Wu on 10/2/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCConfirmPaymentView.h"
#import "NSNumberFormatter+Currencies.h"
#import "UIView+ChangeFrameAttribute.h"

#define CELL_HEIGHT 44

const int cellRowFrom = 0;
const int cellRowTo = 1;
const int cellRowAmount = 2;
const int cellRowFee = 3;

@interface BCConfirmPaymentView () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;
@property (nonatomic) uint64_t amount;
@property (nonatomic) uint64_t fee;
@end
@implementation BCConfirmPaymentView

- (id)initWithWindow:(UIView *)window from:(NSString *)from To:(NSString *)to amount:(uint64_t)amount fee:(uint64_t)fee total:(uint64_t)total surge:(BOOL)surgePresent
{
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
    
    if (self) {
        
        self.reallyDoPaymentButton = [[UIButton alloc] initWithFrame:CGRectMake(0, window.frame.size.height - 40, window.frame.size.width, 40)];
        self.reallyDoPaymentButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
        [self.reallyDoPaymentButton setTitle:BC_STRING_SEND forState:UIControlStateNormal];
        self.reallyDoPaymentButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
        [self addSubview:self.reallyDoPaymentButton];
        
        self.from = from;
        self.to = to;
        self.amount = amount;
        self.fee = fee;
        
        self.backgroundColor = [UIColor whiteColor];
        
        UILabel *totalLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 8, 0, 0)];
        totalLabel.text = BC_STRING_TOTAL;
        totalLabel.textColor = [UIColor darkGrayColor];
        totalLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_SMALL];
        totalLabel.textAlignment = NSTextAlignmentCenter;
        [totalLabel sizeToFit];
        totalLabel.center = CGPointMake(window.center.x, totalLabel.center.y);
        [self addSubview:totalLabel];
        
        UILabel *btcAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, totalLabel.frame.origin.y + totalLabel.frame.size.height + 8, 0, 0)];
        btcAmountLabel.text = [NSNumberFormatter formatBTC:total];
        btcAmountLabel.textColor = COLOR_BLOCKCHAIN_RED;
        btcAmountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_EXTRA_EXTRA_LARGE];
        btcAmountLabel.textAlignment = NSTextAlignmentCenter;
        [btcAmountLabel sizeToFit];
        btcAmountLabel.center = CGPointMake(window.center.x, btcAmountLabel.center.y);
        [self addSubview:btcAmountLabel];
        
        UILabel *fiatAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, btcAmountLabel.frame.origin.y + btcAmountLabel.frame.size.height + 8, 0, 0)];
        fiatAmountLabel.text = [NSNumberFormatter formatMoney:total localCurrency:YES];
        fiatAmountLabel.textColor = COLOR_BLOCKCHAIN_RED;
        fiatAmountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
        fiatAmountLabel.textAlignment = NSTextAlignmentCenter;
        [fiatAmountLabel sizeToFit];
        fiatAmountLabel.center = CGPointMake(window.center.x, fiatAmountLabel.center.y);
        [self addSubview:fiatAmountLabel];
        
        CGFloat tableViewHeight = CELL_HEIGHT * 4;
        
        UITableView *summaryTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, fiatAmountLabel.frame.origin.y + fiatAmountLabel.frame.size.height + 20, window.frame.size.width, tableViewHeight)];
        summaryTableView.scrollEnabled = NO;
        summaryTableView.delegate = self;
        summaryTableView.dataSource = self;
        [self addSubview:summaryTableView];
        
        CGFloat lineWidth = 1.0/[UIScreen mainScreen].scale;
        
        summaryTableView.clipsToBounds = YES;
        
        CALayer *topBorder = [CALayer layer];
        topBorder.borderColor = [COLOR_LINE_GRAY CGColor];
        topBorder.borderWidth = 1;
        topBorder.frame = CGRectMake(0, 0, CGRectGetWidth(summaryTableView.frame), lineWidth);
        [summaryTableView.layer addSublayer:topBorder];
        
        CALayer *bottomBorder = [CALayer layer];
        bottomBorder.borderColor = [COLOR_LINE_GRAY CGColor];
        bottomBorder.borderWidth = 1;
        bottomBorder.frame = CGRectMake(0, CGRectGetHeight(summaryTableView.frame) - lineWidth, CGRectGetWidth(summaryTableView.frame), lineWidth);
        [summaryTableView.layer addSublayer:bottomBorder];
    }
    return self;
}

#pragma mark - Text Helpers

- (NSString *)formatAmountInBTCAndFiat:(uint64_t)amount
{
    return [NSString stringWithFormat:@"%@ (%@)", [NSNumberFormatter formatMoney:amount localCurrency:NO], [NSNumberFormatter formatMoney:amount localCurrency:YES]];
}

#pragma mark - Table View Delegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    cell.selectionStyle = UITableViewCellSelectionStyleNone;
    
    cell.textLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.textLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_SEMIBOLD size:FONT_SIZE_SMALL];
    cell.detailTextLabel.textColor = COLOR_TEXT_DARK_GRAY;
    cell.detailTextLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    
    if (indexPath.row == cellRowTo) {
        cell.textLabel.text = BC_STRING_TO;
        cell.detailTextLabel.text = self.to;
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    } else if (indexPath.row == cellRowFrom) {
        cell.textLabel.text = BC_STRING_FROM;
        cell.detailTextLabel.text = self.from;
        cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
    } else if (indexPath.row == cellRowAmount) {
        cell.textLabel.text = BC_STRING_AMOUNT;
        cell.detailTextLabel.text = [self formatAmountInBTCAndFiat:self.amount];
    } else if (indexPath.row == cellRowFee) {
        cell.textLabel.text = BC_STRING_FEE;
        cell.detailTextLabel.text = [self formatAmountInBTCAndFiat:self.fee];
    }
    return cell;
}

@end

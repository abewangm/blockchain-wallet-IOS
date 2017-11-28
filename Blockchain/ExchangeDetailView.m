//
//  ExchangeDetailView.m
//  Blockchain
//
//  Created by Maurice A. on 11/20/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeDetailView.h"
#import "ExchangeTrade.h"
#import "BCLine.h"
#import "UIView+ChangeFrameAttribute.h"

#define MARGIN_HORIZONTAL 20
#define NUMBER_OF_ROWS 5
#define ROW_HEIGHT_EXCHANGE_DETAIL_VIEW 60

@implementation ExchangeDetailView

- (instancetype)initWithFrame:(CGRect)frame trade:(ExchangeTrade *)trade
{
    self = [super initWithFrame:frame];
    if (self) {
        [self changeHeight:NUMBER_OF_ROWS * ROW_HEIGHT_EXCHANGE_DETAIL_VIEW];
        [self setupPseudoTableWithTrade: trade];
    }
    return self;
}

- (void)setupPseudoTableWithTrade:(ExchangeTrade *)trade
{
    // Rendering Logic
    NSArray *components = [trade.pair componentsSeparatedByString:@"_"];
    NSString *depositCurrency = [components.firstObject isEqual: @"BTC"] ? @"Bitcoin" : @"Ethereum";
    NSString *receiveCurrency = [components.firstObject isEqual: @"BTC"] ? @"Ethereum" : @"Bitcoin";
    NSString *depositAmount = [NSString stringWithFormat:@"%@ %@", trade.depositAmount, components.firstObject];
    NSString *withdrawAmount = [NSString stringWithFormat:@"%@ %@", trade.withdrawalAmount, components[1]];
    NSString *transactionFee = [NSString stringWithFormat:@"%@ %@", trade.transactionFee, components.firstObject];

    UIView *rowDeposit = [self rowViewWithText:[NSString stringWithFormat:BC_STRING_ARGUMENT_TO_DEPOSIT, depositCurrency] accessoryText:depositAmount yPosition:0];
    [self addSubview:rowDeposit];

    UIView *rowReceive = [self rowViewWithText:[NSString stringWithFormat:BC_STRING_ARGUMENT_TO_BE_RECEIVED, receiveCurrency] accessoryText:withdrawAmount yPosition:rowDeposit.frame.origin.y + rowDeposit.frame.size.height];
    [self addSubview:rowReceive];

    UIView *rowExchangeRate = [self rowViewWithText:BC_STRING_EXCHANGE_RATE accessoryText:@"" yPosition:rowReceive.frame.origin.y + rowReceive.frame.size.height];
    [self addSubview:rowExchangeRate];

    UIView *rowTransactionFee = [self rowViewWithText:BC_STRING_TRANSACTION_FEE accessoryText:transactionFee yPosition:rowExchangeRate.frame.origin.y + rowExchangeRate.frame.size.height];
    [self addSubview:rowTransactionFee];

    UIView *rowOrderID = [self rowViewWithText:[NSString stringWithFormat:BC_STRING_EXCHANGE_ORDER_ID, @""] accessoryText:trade.orderID yPosition:rowTransactionFee.frame.origin.y + rowTransactionFee.frame.size.height];
    [self addSubview:rowOrderID];

    BCLine *bottomLine = [[BCLine alloc] initWithYPosition:rowOrderID.frame.origin.y + rowOrderID.frame.size.height];
    [self addSubview:bottomLine];
}

- (UIView *)rowViewWithText:(NSString *)text accessoryText:(NSString *)accessoryText yPosition:(CGFloat)posY
{
    CGFloat horizontalMargin = MARGIN_HORIZONTAL;
    CGFloat rowWidth = WINDOW_WIDTH;
    CGFloat rowHeight = ROW_HEIGHT_EXCHANGE_DETAIL_VIEW;
    UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(0, posY, rowWidth, rowHeight)];

    UILabel *mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalMargin, 0, rowWidth/2, rowHeight)];
    mainLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
    mainLabel.text = text;
    [rowView addSubview:mainLabel];

    UILabel *accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(rowWidth/2, 0, rowWidth/2 - horizontalMargin, rowHeight)];
    accessoryLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
    accessoryLabel.text = accessoryText;
    accessoryLabel.textAlignment = NSTextAlignmentRight;
    accessoryLabel.numberOfLines = 0;
    [rowView addSubview:accessoryLabel];

    BCLine *topLine = [[BCLine alloc] initWithYPosition:posY];
    [self addSubview:topLine];

    return rowView;
}

@end

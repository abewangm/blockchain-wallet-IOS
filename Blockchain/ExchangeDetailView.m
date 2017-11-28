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

#define MARGIN_HORIZONTAL 20

@implementation ExchangeDetailView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self != nil) {}
    return self;
}

- (void)createPseudoTableWithTrade:(ExchangeTrade *)trade
{
    // Rendering Logic
    NSArray *components = [trade.pair componentsSeparatedByString:@"_"];
    NSString *depositCurrency = [components[0] isEqual: @"BTC"] ? @"Bitcoin" : @"Ethereum";
    NSString *receiveCurrency = [components[0] isEqual: @"BTC"] ? @"Ethereum" : @"Bitcoin";
    NSString *depositAmount = [NSString stringWithFormat:@"%@ %@", trade.depositAmount, components[0]];
    NSString *withdrawAmount = [NSString stringWithFormat:@"%@ %@", trade.withdrawalAmount, components[1]];
    NSString *transactionFee = [NSString stringWithFormat:@"%@ %@", trade.transactionFee, components[0]];

    UIView *rowDeposit = [self rowViewWithText:[NSString stringWithFormat:BC_STRING_ARGUMENT_TO_DEPOSIT, depositCurrency] accessoryText:depositAmount yPosition:DEFAULT_HEADER_HEIGHT];
    [self addSubview:rowDeposit];

    UIView *rowReceive = [self rowViewWithText:[NSString stringWithFormat:BC_STRING_ARGUMENT_TO_BE_RECEIVED, receiveCurrency] accessoryText:withdrawAmount yPosition:rowDeposit.frame.origin.y + rowDeposit.frame.size.height];
    [self addSubview:rowReceive];

    UIView *rowExchangeRate = [self rowViewWithText:BC_STRING_EXCHANGE_RATE accessoryText:@"" yPosition:rowReceive.frame.origin.y + rowReceive.frame.size.height];
    [self addSubview:rowExchangeRate];

    UIView *rowTransactionFee = [self rowViewWithText:BC_STRING_TRANSACTION_FEE accessoryText:transactionFee yPosition:rowExchangeRate.frame.origin.y + rowExchangeRate.frame.size.height];
    [self addSubview:rowTransactionFee];

    UIView *rowOrderID = [self rowViewWithText:[NSString stringWithFormat:BC_STRING_EXCHANGE_ORDER_ID, @""] accessoryText:trade.orderID yPosition:rowTransactionFee.frame.origin.y + rowTransactionFee.frame.size.height];
    [self addSubview:rowOrderID];
}

- (UIView *)rowViewWithText:(NSString *)text accessoryText:(NSString *)accessoryText yPosition:(CGFloat)posY
{
    CGFloat horizontalMargin = MARGIN_HORIZONTAL;
    CGFloat rowWidth = WINDOW_WIDTH;
    CGFloat rowHeight = 60;
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

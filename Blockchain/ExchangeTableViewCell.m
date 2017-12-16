//
//  ExchangeTableViewCell.m
//  Blockchain
//
//  Created by kevinwu on 11/13/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeTableViewCell.h"
#import "NSDateFormatter+TimeAgoString.h"
#import "RootService.h"
#import "NSNumberFormatter+Currencies.h"

@implementation ExchangeTableViewCell

- (void)configureWithTrade:(ExchangeTrade *)trade
{
    NSString *status = trade.status;
    
    NSString *displayStatus;
    UIColor *statusColor;
    if ([status isEqualToString:TRADE_STATUS_COMPLETE]) {
        statusColor = COLOR_BLOCKCHAIN_GREEN;
        displayStatus = BC_STRING_COMPLETE;
    } else if ([status isEqualToString:TRADE_STATUS_NO_DEPOSITS] ||
               [status isEqualToString:TRADE_STATUS_RECEIVED]) {
        statusColor = COLOR_BLOCKCHAIN_GRAY_BLUE;
        displayStatus = BC_STRING_IN_PROGRESS;
    } else if ([status isEqualToString:TRADE_STATUS_CANCELLED] ||
               [status isEqualToString:TRADE_STATUS_FAILED] ||
               [status isEqualToString:TRADE_STATUS_EXPIRED] ||
               [status isEqualToString:TRADE_STATUS_RESOLVED]) {
        statusColor = COLOR_BLOCKCHAIN_RED;
        displayStatus = BC_STRING_FAILED;
    }
    
    self.actionLabel.textColor = statusColor;
    
    self.actionLabel.text = [displayStatus uppercaseString];
    self.amountButton.backgroundColor = statusColor;
    
    NSString *toAsset = [[trade.pair componentsSeparatedByString:@"_"] lastObject];
    NSString *amountString;
    
    if (app->symbolLocal) {
        if ([[[trade withdrawalCurrency] lowercaseString] isEqualToString:[CURRENCY_SYMBOL_BTC lowercaseString]]) {
            amountString = [NSNumberFormatter formatMoney:ABS([NSNumberFormatter parseBtcValueFromString:[trade.withdrawalAmount stringValue]])];
        } else if ([[[trade withdrawalCurrency] lowercaseString] isEqualToString:[CURRENCY_SYMBOL_ETH lowercaseString]]) {
            amountString = [NSNumberFormatter formatEthWithLocalSymbol:[trade.withdrawalAmount stringValue] exchangeRate:app.tabControllerManager.latestEthExchangeRate];
        } else {
            DLog(@"Warning: unsupported withdrawal currency for trade: %@", [trade withdrawalCurrency]);
        }
    } else {
        amountString = [NSString stringWithFormat:@"%@ %@", [trade.withdrawalAmount stringValue], [toAsset uppercaseString]];
    }
    
    [self.amountButton setTitle:amountString forState:UIControlStateNormal];
    self.dateLabel.text = [NSDateFormatter timeAgoStringFromDate:trade.date];
}

- (IBAction)amountButtonClicked:(id)sender
{
    [app toggleSymbol];
}

@end

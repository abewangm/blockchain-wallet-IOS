//
//  ExchangeTrade.m
//  Blockchain
//
//  Created by kevinwu on 11/13/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeTrade.h"

#define DICTIONARY_KEY_STATUS @"status"
#define DICTIONARY_KEY_PAIR @"pair"
#define DICTIONARY_KEY_QUOTE @"quote"
#define DICTIONARY_KEY_ORDER_ID @"orderId"
#define DICTIONARY_KEY_WITHDRAWAL_AMOUNT @"withdrawalAmount"
#define DICTIONARY_KEY_DEPOSIT_AMOUNT @"depositAmount"
#define DICTIONARY_KEY_MINER_FEE @"minerFee"

@implementation ExchangeTrade

+ (ExchangeTrade *)fromJSONDict:(NSDictionary *)dict
{
    ExchangeTrade *trade = [[ExchangeTrade alloc] init];
    trade.date = [dict objectForKey:DICTIONARY_KEY_TIME];
    trade.status = [dict objectForKey:DICTIONARY_KEY_STATUS];
    
    NSDictionary *quote = [dict objectForKey:DICTIONARY_KEY_QUOTE];
    trade.orderID = [quote objectForKey:DICTIONARY_KEY_ORDER_ID];
    trade.pair = [quote objectForKey:DICTIONARY_KEY_PAIR];
    trade.depositAmount = [[NSDecimalNumber alloc] initWithDecimal:[[quote objectForKey:DICTIONARY_KEY_DEPOSIT_AMOUNT] decimalValue]];
    trade.withdrawalAmount = [quote objectForKey:DICTIONARY_KEY_WITHDRAWAL_AMOUNT];
    trade.transactionFee = [quote objectForKey:DICTIONARY_KEY_MINER_FEE];
    return trade;
}

@end

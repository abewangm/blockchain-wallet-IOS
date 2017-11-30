//
//  ExchangeTrade.m
//  Blockchain
//
//  Created by kevinwu on 11/13/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeTrade.h"

@implementation ExchangeTrade

+ (ExchangeTrade *)fetchedTradeFromJSONDict:(NSDictionary *)dict
{
    ExchangeTrade *trade = [[ExchangeTrade alloc] init];
    
    trade.date = [dict objectForKey:DICTIONARY_KEY_TIME];
    trade.status = [dict objectForKey:DICTIONARY_KEY_STATUS];
    
    NSDictionary *quote = [dict objectForKey:DICTIONARY_KEY_QUOTE];
    trade.orderID = [quote objectForKey:DICTIONARY_KEY_ORDER_ID];
    trade.pair = [quote objectForKey:DICTIONARY_KEY_PAIR];
    trade.depositAmount = [ExchangeTrade decimalNumberFromDictValue:[quote objectForKey:DICTIONARY_KEY_DEPOSIT_AMOUNT]];
    trade.withdrawalAmount = [ExchangeTrade decimalNumberFromDictValue:[quote objectForKey:DICTIONARY_KEY_WITHDRAWAL_AMOUNT]];
    trade.transactionFee = [ExchangeTrade decimalNumberFromDictValue:[quote objectForKey:DICTIONARY_KEY_MINER_FEE]];
    return trade;
}

+ (ExchangeTrade *)builtTradeFromJSONDict:(NSDictionary *)dict
{
    ExchangeTrade *trade = [[ExchangeTrade alloc] init];
    trade.depositAmount = [ExchangeTrade decimalNumberFromDictValue:[dict objectForKey:DICTIONARY_KEY_DEPOSIT_AMOUNT]];
    trade.withdrawalAmount = [ExchangeTrade decimalNumberFromDictValue:[dict objectForKey:DICTIONARY_KEY_WITHDRAWAL_AMOUNT]];
    trade.transactionFee = [ExchangeTrade decimalNumberFromDictValue:[dict objectForKey:DICTIONARY_KEY_MINER_FEE]];
    trade.expirationDate = [dict objectForKey:DICTIONARY_KEY_EXPIRATION_DATE];
    
    return trade;
}

+ (NSDecimalNumber *)decimalNumberFromDictValue:(id)value
{
    NSDecimalNumber *decimalNumber;
    if ([value isKindOfClass:[NSString class]]) {
        decimalNumber = [NSDecimalNumber decimalNumberWithString:value];
    } else if ([value isKindOfClass:[NSNumber class]]) {
        decimalNumber = [[NSDecimalNumber alloc] initWithDecimal:[value decimalValue]];
    }
    
    return decimalNumber;
}

@end

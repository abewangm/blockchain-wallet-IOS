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
#define DICTIONARY_KEY_WITHDRAWAL_AMOUNT @"withdrawalAmount"
#define DICTIONARY_KEY_DEPOSIT_AMOUNT @"depositAmount"

@implementation ExchangeTrade

+ (ExchangeTrade *)fromJSONDict:(NSDictionary *)dict
{
    ExchangeTrade *trade = [[ExchangeTrade alloc] init];
    trade.time = [[dict objectForKey:DICTIONARY_KEY_TIME] timeIntervalSince1970];
    trade.status = [dict objectForKey:DICTIONARY_KEY_STATUS];
    trade.pair = [dict objectForKey:DICTIONARY_KEY_PAIR];
    
    NSDictionary *quote = [dict objectForKey:DICTIONARY_KEY_QUOTE];
    trade.depositAmount = [quote objectForKey:DICTIONARY_KEY_DEPOSIT_AMOUNT];
    trade.withdrawalAmount = [quote objectForKey:DICTIONARY_KEY_WITHDRAWAL_AMOUNT];
    return trade;
}

@end

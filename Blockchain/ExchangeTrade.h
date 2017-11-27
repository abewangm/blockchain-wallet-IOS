//
//  ExchangeTrade.h
//  Blockchain
//
//  Created by kevinwu on 11/13/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

#define TRADE_STATUS_COMPLETE @"COMPLETE"
#define TRADE_STATUS_IN_PROGRESS @"IN_PROGRESS"
#define TRADE_STATUS_CANCELED @"CANCELED"
#define TRADE_STATUS_FAILED @"FAILED"
#define TRADE_STATUS_EXPIRED @"EXPIRED"

@interface ExchangeTrade : NSObject
@property (nonatomic) NSString *orderID;
@property (nonatomic) NSDate *date;
@property (nonatomic) NSString *status;
@property (nonatomic) NSString *pair;
@property (nonatomic) NSDecimalNumber *depositAmount;
@property (nonatomic) NSDecimalNumber *withdrawalAmount;
@property (nonatomic) NSDecimalNumber *transactionFee;

+ (ExchangeTrade *)fromJSONDict:(NSDictionary *)dict;

@end

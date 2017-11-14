//
//  ExchangeTrade.h
//  Blockchain
//
//  Created by kevinwu on 11/13/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ExchangeTrade : NSObject
@property (nonatomic) NSDate *date;
@property (nonatomic) NSString *status;
@property (nonatomic) NSString *pair;
@property (nonatomic) NSString *depositAmount;
@property (nonatomic) NSString *withdrawalAmount;

+ (ExchangeTrade *)fromJSONDict:(NSDictionary *)dict;

@end

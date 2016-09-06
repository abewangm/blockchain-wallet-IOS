//
//  NSNumberFormatter+Currencies.h
//  Blockchain
//
//  Created by Kevin Wu on 8/22/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSNumberFormatter (Currencies)

+ (NSString*)formatMoney:(uint64_t)value;
+ (NSString*)formatMoney:(uint64_t)value localCurrency:(BOOL)fsymbolLocal;
+ (NSString *)formatAmount:(uint64_t)amount localCurrency:(BOOL)localCurrency;
+ (BOOL)stringHasBitcoinValue:(NSString *)string;
+ (NSString *)appendNumberToFiatSymbol:(NSNumber *)number;
+ (NSString *)formatMoneyWithLocalSymbol:(uint64_t)value;
@end

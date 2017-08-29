//
//  NSNumberFormatter+Currencies.m
//  Blockchain
//
//  Created by Kevin Wu on 8/22/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "NSNumberFormatter+Currencies.h"
#import "RootService.h"

@implementation NSNumberFormatter (Currencies)

#pragma mark - Format helpers

// Format amount in satoshi as NSString (with symbol)
+ (NSString*)formatMoney:(uint64_t)value localCurrency:(BOOL)fsymbolLocal
{
    if (fsymbolLocal && app.latestResponse.symbol_local.conversion) {
        @try {
            NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(double)app.latestResponse.symbol_local.conversion]];
            
            return [app.latestResponse.symbol_local.symbol stringByAppendingString:[app.localCurrencyFormatter stringFromNumber:number]];
            
        } @catch (NSException * e) {
            DLog(@"Exception: %@", e);
        }
    } else if (app.latestResponse.symbol_btc) {
        NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:app.latestResponse.symbol_btc.conversion]];
        
        // mBTC display -> Always 2 decimal places
        if (app.latestResponse.symbol_btc.conversion == 100) {
            [app.btcFormatter setMinimumFractionDigits:2];
        }
        // otherwise -> no min decimal places
        else {
            [app.btcFormatter setMinimumFractionDigits:0];
        }
        
        NSString * string = [app.btcFormatter stringFromNumber:number];
        
        return [string stringByAppendingFormat:@" %@", app.latestResponse.symbol_btc.symbol];
    }
    
    return [NSNumberFormatter formatBTC:value];
}

+ (NSString*)formatBTC:(uint64_t)value
{
    NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:SATOSHI]];
    
    [app.btcFormatter setMinimumFractionDigits:0];
    
    NSString * string = [app.btcFormatter stringFromNumber:number];
    
    return [string stringByAppendingString:@" BTC"];
}

+ (NSString*)formatMoney:(uint64_t)value
{
    return [self formatMoney:value localCurrency:app->symbolLocal];
}

// Format amount in satoshi as NSString (without symbol)
+ (NSString *)formatAmount:(uint64_t)amount localCurrency:(BOOL)localCurrency
{
    if (amount == 0) {
        return nil;
    }
    
    NSString *returnValue;
    
    if (localCurrency) {
        @try {
            NSDecimalNumber *number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:amount] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(double)app.latestResponse.symbol_local.conversion]];
            
            app.localCurrencyFormatter.usesGroupingSeparator = NO;
            returnValue = [app.localCurrencyFormatter stringFromNumber:number];
            app.localCurrencyFormatter.usesGroupingSeparator = YES;
        } @catch (NSException * e) {
            DLog(@"Exception: %@", e);
        }
    } else {
        @try {
            NSDecimalNumber *number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:amount] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:app.latestResponse.symbol_btc.conversion]];
            
            app.btcFormatter.usesGroupingSeparator = NO;
            returnValue = [app.btcFormatter stringFromNumber:number];
            app.btcFormatter.usesGroupingSeparator = YES;
        } @catch (NSException * e) {
            DLog(@"Exception: %@", e);
        }
    }
    
    return returnValue;
}

+ (BOOL)stringHasBitcoinValue:(NSString *)string
{
    return string != nil && [string doubleValue] > 0;
}

+ (NSString *)appendStringToFiatSymbol:(NSString *)string
{
    return [app.latestResponse.symbol_local.symbol stringByAppendingFormat:@"%@", string];
}

+ (NSString *)formatMoneyWithLocalSymbol:(uint64_t)value
{
    return [self formatMoney:value localCurrency:app->symbolLocal];
}

#pragma mark - Ether

+ (NSDecimalNumber *)convertEthToFiat:(NSDecimalNumber *)ethAmount exchangeRate:(NSDecimalNumber *)exchangeRate
{
    if (ethAmount == 0) return 0;
    
    return [ethAmount decimalNumberByMultiplyingBy:exchangeRate];
}

+ (NSString *)formatEthToFiat:(NSString *)ethAmount exchangeRate:(NSDecimalNumber *)exchangeRate
{
    if (ethAmount != nil && [ethAmount doubleValue] > 0) {
        NSDecimalNumber *ethAmountDecimalNumber = [NSDecimalNumber decimalNumberWithString:ethAmount];
        return [NSString stringWithFormat:@"%@", [NSNumberFormatter convertEthToFiat:ethAmountDecimalNumber exchangeRate:exchangeRate]];
    } else {
        return nil;
    }
}

+ (NSString *)formatEthToFiatWithSymbol:(NSString *)ethAmount exchangeRate:(NSDecimalNumber *)exchangeRate
{
    NSString *formatString = [NSNumberFormatter formatEthToFiat:ethAmount exchangeRate:exchangeRate];
    if (!formatString) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@%@", app.latestResponse.symbol_local.symbol, formatString];
    }
}

+ (NSDecimalNumber *)convertFiatToEth:(NSDecimalNumber *)fiatAmount exchangeRate:(NSDecimalNumber *)exchangeRate
{
    if (fiatAmount == 0) return 0;
    
    return [fiatAmount decimalNumberByDividingBy:exchangeRate];
}

+ (NSString *)formatFiatToEth:(NSString *)fiatAmount exchangeRate:(NSDecimalNumber *)exchangeRate
{
    if (fiatAmount != nil && [fiatAmount doubleValue] > 0) {
        NSDecimalNumber *fiatAmountDecimalNumber = [NSDecimalNumber decimalNumberWithString:fiatAmount];
        return [NSString stringWithFormat:@"%@", [NSNumberFormatter convertFiatToEth:fiatAmountDecimalNumber exchangeRate:exchangeRate]];
    } else {
        return nil;
    }
}

+ (NSString *)formatFiatToEthWithSymbol:(NSString *)ethAmount exchangeRate:(NSDecimalNumber *)exchangeRate
{
    NSString *formatString = [NSNumberFormatter formatFiatToEth:ethAmount exchangeRate:exchangeRate];
    if (!formatString) {
        return nil;
    } else {
        return [NSString stringWithFormat:@"%@ %@", app.latestResponse.symbol_local.code, formatString];
    }
}


@end

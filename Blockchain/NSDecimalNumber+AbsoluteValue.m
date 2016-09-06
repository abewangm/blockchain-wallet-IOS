//
//  NSDecimalNumber+AbsoluteValue.m
//  Blockchain
//
//  Created by Kevin Wu on 9/6/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "NSDecimalNumber+AbsoluteValue.h"

@implementation NSDecimalNumber (AbsoluteValue)

- (NSDecimalNumber *)absoluteValue
{
    if ([self compare:[NSDecimalNumber zero]] == NSOrderedAscending) {
        // Number is negative. Multiply by -1
        NSDecimalNumber *negativeOne = [NSDecimalNumber decimalNumberWithMantissa:1
                                                                         exponent:0
                                                                       isNegative:YES];
        return [self decimalNumberByMultiplyingBy:negativeOne];
    } else {
        return self;
    }
}

@end

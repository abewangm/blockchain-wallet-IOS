//
//  NSString+Hex.m
//  Blockchain
//
//  Created by kevinwu on 2/23/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "NSString+Hex.h"

@implementation NSString (Hex)

- (BOOL)isHexadecimal
{
    NSCharacterSet *chars = [[NSCharacterSet
                              characterSetWithCharactersInString:@"0123456789ABCDEFabcdef"] invertedSet];
    
    BOOL isValid = (NSNotFound == [self rangeOfCharacterFromSet:chars].location);
    return isValid;
}

@end

//
//  PasswordStrengthChecker.m
//  Blockchain
//
//  Created by Kevin Wu on 7/17/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "PasswordStrengthChecker.h"

#define PASSWORD_ONE_UPPERCASE @"^(?=.*[A-Z]).*$"  //Should contain one or more uppercase letters
#define PASSWORD_ONE_LOWERCASE @"^(?=.*[a-z]).*$"  //Should contain one or more lowercase letters
#define PASSWORD_ONE_NUMBER @"^(?=.*[0-9]).*$"  //Should contain one or more number
#define PASSWORD_ONE_SYMBOL @"^(?=.*[!@#$%&_]).*$"  //Should contain one or more symbol

@interface PasswordStrengthChecker()

@end

@implementation PasswordStrengthChecker

+ (PasswordStrengthType)checkPasswordStrength:(NSString *)password
{
    NSInteger len = password.length;
    int strength = 0;
    
    if (len == 0) {
        return PasswordStrengthTypeWeak;
    } else if (len <= 5) {
        strength++;
    } else if (len <= 10) {
        strength += 2;
    } else {
        strength += 3;
    }
    
    strength += [self validateString:password withPattern:PASSWORD_ONE_UPPERCASE caseSensitive:YES];
    strength += [self validateString:password withPattern:PASSWORD_ONE_LOWERCASE caseSensitive:YES];
    strength += [self validateString:password withPattern:PASSWORD_ONE_NUMBER caseSensitive:YES];
    strength += [self validateString:password withPattern:PASSWORD_ONE_SYMBOL caseSensitive:YES];
    
    if (strength <= 3) {
        return PasswordStrengthTypeWeak;
    } else if (3 < strength && strength < 6) {
        return PasswordStrengthTypeModerate;
    } else {
        return PasswordStrengthTypeStrong;
    }
}

+ (int)validateString:(NSString *)string withPattern:(NSString *)pattern caseSensitive:(BOOL)caseSensitive
{
    NSError *error;
    NSRegularExpression *regularExpression = [NSRegularExpression regularExpressionWithPattern:pattern options:((caseSensitive) ? 0 : NSRegularExpressionCaseInsensitive) error:&error];
    
    NSAssert(regularExpression, @"Unable to create regular expression");
    
    NSRange textRange = NSMakeRange(0, string.length);
    NSRange matchRange = [regularExpression rangeOfFirstMatchInString:string options:NSMatchingReportProgress range:textRange];
    
    BOOL didValidate = 0;
    
    // Did we find a matching range
    if (matchRange.location != NSNotFound)
        didValidate = 1;
    
    return didValidate;
}

@end

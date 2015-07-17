//
//  PasswordStrengthChecker.h
//  Blockchain
//
//  Created by Kevin Wu on 7/17/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef enum {
    PasswordStrengthTypeWeak,
    PasswordStrengthTypeModerate,
    PasswordStrengthTypeStrong
} PasswordStrengthType;

@interface PasswordStrengthChecker : NSObject

+ (PasswordStrengthType)checkPasswordStrength:(NSString *)password;

@end

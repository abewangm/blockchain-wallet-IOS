//
//  Merchant.m
//  Blockchain
//
//  Created by User on 12/18/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "Merchant.h"

#import "Foundation-Utility.h"

NSString *const kMerchantIdKey = @"id";
NSString *const kMerchantNameKey = @"name";
NSString *const kMerchantAdressKey = @"address";
NSString *const kMerchantCityKey = @"city";
NSString *const kMerchantPCodeKey = @"postal_code";
NSString *const kMerchantTelphoneKey = @"phone";
NSString *const kMerchantURLKey = @"website";
NSString *const kMerchantLatitudeKey = @"latitude";
NSString *const kMerchantLongitudeKey = @"longitude";
NSString *const kMerchantTypeKey = @"category_id";
NSString *const kMerchantDescriptionKey = @"description";

@interface Merchant ()

@property (assign, nonatomic) BCMerchantLocationType locationType;

@end

@implementation Merchant

+ (Merchant *)merchantWithDict:(NSDictionary *)dict
{
    Merchant *merchant = [[Merchant alloc] init];

    if ([dict respondsToSelector:@selector(safeObjectForKey:)]) {
        merchant.merchantId = [dict safeObjectForKey:kMerchantIdKey];
        merchant.name = [dict safeObjectForKey:kMerchantNameKey];
        merchant.address = [dict safeObjectForKey:kMerchantAdressKey];
        merchant.city = [dict safeObjectForKey:kMerchantCityKey];
        merchant.pcode = [dict safeObjectForKey:kMerchantPCodeKey];
        merchant.telephone = [dict safeObjectForKey:kMerchantTelphoneKey];
        merchant.urlString = [dict safeObjectForKey:kMerchantURLKey];
        merchant.latitude = [dict safeObjectForKey:kMerchantLatitudeKey];
        merchant.longitude = [dict safeObjectForKey:kMerchantLongitudeKey];
        merchant.longitude = [dict safeObjectForKey:kMerchantLongitudeKey];
        
        NSString *merchantType = [dict safeObjectForKey:kMerchantTypeKey];
        BCMerchantLocationType locationType = BCMerchantLocationTypeOther;
        if ([merchantType isEqual:@1]) {
            locationType = BCMerchantLocationTypeBeverage;
        } else if ([merchantType isEqual:@2]) {
            locationType = BCMerchantLocationTypeBar;
        } else if ([merchantType isEqual:@3]) {
            locationType = BCMerchantLocationTypeFood;
        } else if ([merchantType isEqual:@4]) {
            locationType = BCMerchantLocationTypeBusiness;
        } else if ([merchantType isEqual:@5]) {
            locationType = BCMerchantLocationTypeOther;
        }
        merchant.locationType = locationType;
        
        merchant.merchantDescription = [dict safeObjectForKey:kMerchantDescriptionKey];
        
        return merchant;
    } else {
        return nil;
    }
}

- (NSString *)latLongQueryString
{
    NSString *queryString = @"";
    
    if ([self.latitude length] > 0) {
        queryString = [queryString stringByAppendingString:self.latitude];
    }
    
    if ([self.longitude length] > 0) {
        if ([queryString length] > 0) {
            queryString = [queryString stringByAppendingString:@","];
        }
        queryString = [queryString stringByAppendingString:self.longitude];
    }
    
    return queryString;
}

- (NSString *)addressQueryString
{
    NSString *addressString = @"";
    
    if ([self.address length] > 0) {
        addressString = self.address;
    }
    
    if ([self.city length] > 0) {
        if ([addressString length] > 0) {
            addressString = [addressString stringByAppendingString:@" "];
        }
        addressString = [addressString stringByAppendingString:self.city];
    }
    
    return addressString;
}

@end

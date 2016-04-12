//
//  DeviceIdentifier.m
//  Blockchain
//
//  Created by Kevin Wu on 11/12/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//

#import "DeviceIdentifier.h"
#import <sys/utsname.h>

@implementation DeviceIdentifier

+ (NSString *)deviceName
{
    NSString *identifier;
    struct utsname systemInfo;
    uname(&systemInfo);
    identifier = [NSString stringWithCString:systemInfo.machine
                                    encoding:NSUTF8StringEncoding];
    
    NSDictionary *deviceDictionary = @{
                                       @"i386": @"Simulator",
                                       @"x86_64": @"Simulator",
                                       @"iPod1,1": @"iPod Touch",
                                       @"iPod2,1": @"iPod Touch 2nd Generation",
                                       @"iPod3,1": @"iPod Touch 3rd Generation",
                                       @"iPod4,1": @"iPod Touch 4th Generation",
                                       @"iPhone1,1": @"iPhone",
                                       @"iPhone1,2": @"iPhone 3G",
                                       @"iPhone2,1": @"iPhone 3GS",
                                       @"iPhone3,1": @"iPhone 4",
                                       @"iPhone4,1": @"iPhone 4S",
                                       @"iPhone5,1": @"iPhone 5",
                                       @"iPhone5,2": @"iPhone 5",
                                       @"iPhone5,3": @"iPhone 5c",
                                       @"iPhone5,4": @"iPhone 5c",
                                       @"iPhone6,1": @"iPhone 5s",
                                       @"iPhone6,2": @"iPhone 5s",
                                       @"iPad1,1": @"iPad",
                                       @"iPad2,1": @"iPad 2",
                                       @"iPad3,1": @"iPad 3rd Generation ",
                                       @"iPad3,4": @"iPad 4th Generation ",
                                       @"iPad2,5": @"iPad Mini",
                                       @"iPad4,4": @"iPad Mini 2nd Generation - Wifi",
                                       @"iPad4,5": @"iPad Mini 2nd Generation - Cellular",
                                       @"iPad4,1": @"iPad Air 5th Generation - Wifi",
                                       @"iPad4,2": @"iPad Air 5th Generation - Cellular",
                                       @"iPhone7,1": @"iPhone 6 Plus",
                                       @"iPhone7,2": @"iPhone 6",
                                       @"iPhone8,1": @"iPhone 6S (GSM+CDMA)",
                                       @"iPhone8,2": @"iPhone 6S+ (GSM+CDMA)",
                                       @"iPhone8,4": @"iPhone SE",
                                       };
    NSString *deviceName = [deviceDictionary objectForKey:identifier];
    if (!deviceName) {
        deviceName = [NSString stringWithFormat:@"Unknown device: identifier %@", identifier];
    }
    return deviceName;
}

@end

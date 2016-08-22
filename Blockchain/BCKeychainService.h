//
//  BCKeychainService.h
//  Blockchain
//
//  Created by Kevin Wu on 8/22/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BCKeychainService : NSObject
+ (NSString *)guid;
+ (NSString *)hashedGuid;
+ (void)setGuidInKeychain:(NSString *)guid;
+ (void)removeGuidFromKeychain;

+ (NSString *)sharedKey;
+ (void)setSharedKeyInKeychain:(NSString *)sharedKey;
+ (void)removeSharedKeyFromKeychain;

+ (void)setPINInKeychain:(NSString *)pin;
+ (NSString *)pinFromKeychain;
+ (void)removePinFromKeychain;
@end

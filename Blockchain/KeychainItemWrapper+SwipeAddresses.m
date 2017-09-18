//
//  KeychainItemWrapper+SwipeAddresses.m
//  Blockchain
//
//  Created by Kevin Wu on 10/21/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "KeychainItemWrapper+SwipeAddresses.h"

@implementation KeychainItemWrapper (SwipeAddresses)

#pragma mark - Swipe To Receive

+ (NSArray *)getSwipeAddresses
{
    return [KeychainItemWrapper getMutableSwipeAddresses];
}

+ (NSMutableArray *)getMutableSwipeAddresses
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_SWIPE_ADDRESSES accessGroup:nil];
    NSData *arrayData = [keychain objectForKey:(__bridge id)kSecValueData];
    NSMutableArray *swipeAddresses = [NSKeyedUnarchiver unarchiveObjectWithData:arrayData];
    
    return swipeAddresses;
}

+ (void)addSwipeAddress:(NSString *)swipeAddress
{
    NSMutableArray *swipeAddresses = [KeychainItemWrapper getMutableSwipeAddresses];
    if (!swipeAddresses) swipeAddresses = [NSMutableArray new];
    [swipeAddresses addObject:swipeAddress];
    
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_SWIPE_ADDRESSES accessGroup:nil];
    [keychain setObject:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    [keychain setObject:KEYCHAIN_KEY_SWIPE_ADDRESSES forKey:(__bridge id)kSecAttrAccount];
    [keychain setObject:[NSKeyedArchiver archivedDataWithRootObject:swipeAddresses] forKey:(__bridge id)kSecValueData];
}

+ (void)removeFirstSwipeAddress
{
    NSMutableArray *swipeAddresses = [KeychainItemWrapper getMutableSwipeAddresses];
    if (swipeAddresses.count > 0) {
        [swipeAddresses removeObjectAtIndex:0];
        
        KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_SWIPE_ADDRESSES accessGroup:nil];
        [keychain setObject:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
        
        [keychain setObject:KEYCHAIN_KEY_SWIPE_ADDRESSES forKey:(__bridge id)kSecAttrAccount];
        [keychain setObject:[NSKeyedArchiver archivedDataWithRootObject:swipeAddresses] forKey:(__bridge id)kSecValueData];
    } else {
        DLog(@"Error removing first swipe address: no swipe addresses stored!");
    }
}

+ (void)removeAllSwipeAddresses
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_SWIPE_ADDRESSES accessGroup:nil];
    [keychain resetKeychainItem];
    
    KeychainItemWrapper *etherKeychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_ETHER_ADDRESS accessGroup:nil];
    [etherKeychain resetKeychainItem];
}

+ (void)setSwipeEtherAddress:(NSString *)swipeAddress
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_ETHER_ADDRESS accessGroup:nil];
    [keychain setObject:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    [keychain setObject:KEYCHAIN_KEY_ETHER_ADDRESS forKey:(__bridge id)kSecAttrAccount];
    [keychain setObject:[swipeAddress dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
}

+ (NSString *)getSwipeEtherAddress
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_ETHER_ADDRESS accessGroup:nil];
    NSData *etherAddressData = [keychain objectForKey:(__bridge id)kSecValueData];
    NSString *etherAddress = [[NSString alloc] initWithData:etherAddressData encoding:NSUTF8StringEncoding];
    
    return etherAddress.length == 0 ? nil : etherAddress;
}

@end

//
//  KeychainItemWrapper+SwipeAddresses.h
//  Blockchain
//
//  Created by Kevin Wu on 10/21/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "KeychainItemWrapper.h"

@interface KeychainItemWrapper (SwipeAddresses)
+ (NSArray *)getSwipeAddresses;
+ (void)addSwipeAddress:(NSString *)swipeAddress;
+ (void)removeFirstSwipeAddress;
+ (void)removeAllSwipeAddresses;

+ (void)setSwipeEtherAddress:(NSString *)swipeAddress;
+ (NSString *)getSwipeEtherAddress;
+ (void)removeSwipeEtherAddress;
@end

//
//  HDNode.h
//  Blockchain
//
//  Created by Kevin Wu on 10/20/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
@class HDNode, BTCKeychain;

@protocol ExportHDNode <JSExport>

// Chain code associated with the key.
@property (readonly) JSValue* chainCode;
@property (readonly) JSValue* keyPair;
@property (readonly) uint8_t depth;
@property (readonly) uint32_t index;
@property (readonly) uint32_t parentFingerprint;
@property (readonly) BTCKeychain *keychain;

+ (HDNode *)fromSeed:(NSString *)seed buffer:(JSValue *)network;
+ (HDNode *)from:(NSString *)seed base58:(JSValue *)networks;
- (NSString *)getAddress;
- (NSString *)getIdentifier;
- (JSValue *)getNetwork;
- (JSValue *)getPublicKeyBuffer;
- (JSValue *)getFingerprint;
- (NSString *)toBase58:(JSValue *)isPrivate;
- (HDNode *)derive:(JSValue *)_index;
- (HDNode *)deriveHardened:(JSValue *)_index;
- (BOOL)isNeutered;
- (HDNode *)derivePath:(JSValue *)path;

@end

@interface HDNode : NSObject <ExportHDNode>
@property BTCKeychain *keychain;
@end

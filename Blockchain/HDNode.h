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
@property JSValue* chainCode;
@property JSValue* keyPair;
@property int depth;
@property int index;
@property int parentFingerprint;
@property BTCKeychain *keychain;

+ (HDNode *)fromSeed:(NSString *)seed buffer:(JSValue *)network;
+ (HDNode *)from:(NSString *)seed base58:(JSValue *)networks;

- (JSValue *)getAddress;
- (NSString *)getIdentifier;
- (JSValue *)getNetwork;
- (JSValue *)getPublicKeyBuffer;
- (JSValue *)getFingerprint;
- (HDNode *)toBase58:(JSValue *)isPrivate;
- (HDNode *)derive:(JSValue *)_index;
- (HDNode *)deriveHardened:(JSValue *)_index;
- (BOOL)isNeutered;
- (HDNode *)derivePath:(JSValue *)path;

@end

@interface HDNode : NSObject <ExportHDNode>
@end

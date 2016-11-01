//
//  HDNode.m
//  Blockchain
//
//  Created by Kevin Wu on 10/20/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "HDNode.h"
#import "BTCBigNumber.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "BTCData.h"
#import "RootService.h"
#import "NSString+NSString_EscapeQuotes.h"
#import "NSData+Hex.h"
#import "BTCCurvePoint.h"
#import "BTCBase58.h"
#import "BTCKeychain.h"
#import "BTCNetwork.h"
#import "BTCKey.h"
#import "BTCAddress.h"

@interface HDNode()
@end
@implementation HDNode

- (JSValue *)keyPair
{
    JSValue *keyPair = [JSValue valueWithNewObjectInContext:app.wallet.context];
    JSValue *buffer = [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"BigInteger.fromBuffer(new Buffer('%@', 'hex'))", [[self.keychain.key.privateKey hexadecimalString] escapeStringForJS]]];
    [keyPair setValue:buffer forProperty:@"d"];
    return keyPair;
}

- (JSValue *)chainCode
{
    return [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", [self.keychain.chainCode hexadecimalString]]];;
}

- (uint32_t)index
{
    return self.keychain.index;
}

- (uint32_t)parentFingerprint
{
    return self.keychain.parentFingerprint;
}

- (uint8_t)depth
{
    return self.keychain.depth;
}

- (id)initWithKeychain:(BTCKeychain *)keychain;
{
    if (self = [super init]) {
        self.keychain = keychain;
    }
    return self;
}

+ (HDNode *)fromSeed:(NSString *)seed network:(JSValue *)network
{
    // TODO: make TestNet compatible
    BTCNetwork *btcNetwork = [BTCNetwork mainnet];
    BTCKeychain *keychain = [[BTCKeychain alloc] initWithSeed:[seed dataUsingEncoding:NSUTF8StringEncoding] network:btcNetwork];

    return [[HDNode alloc] initWithKeychain:keychain];
}

- (NSString *)getAddress
{
    return self.keychain.key.address.string;
}

+ (HDNode *)fromSeed:(NSString *)seed buffer:(JSValue *)network;
{
    return [HDNode fromSeed:seed network:network];
}

+ (HDNode *)fromSeed:(JSValue *)hex hex:(JSValue *)network
{
    JSValue *seed = [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", [hex toString]]];
    return [HDNode fromSeed:[seed toString] buffer:network];
}

+ (HDNode *)from:(NSString *)seed base58:(JSValue *)networks
{
    return [[HDNode alloc] initWithKeychain:[[BTCKeychain alloc] initWithExtendedKey:seed]];
}

- (NSString *)getIdentifier
{
    NSData *data = self.keychain.identifier;
    return [[NSString alloc] initWithBytes:(char *)data.bytes length:data.length encoding:NSUTF8StringEncoding];
}

- (JSValue *)getFingerprint
{
    return [JSValue valueWithInt32:self.keychain.fingerprint inContext:app.wallet.context];
}

- (JSValue *)getNetwork
{
    return [JSValue valueWithObject:self.keychain.network inContext:app.wallet.context];
}

- (JSValue *)getPublicKeyBuffer
{
    return [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", self.keychain.extendedPublicKey]];
}

- (BOOL)isNeutered
{
    return !self.keychain.isPrivate;
}

- (NSString *)toBase58:(JSValue *)isPrivate
{
    if (![isPrivate isUndefined]) {
        @throw [NSException exceptionWithName:@"HDNode Exception"
                                       reason:@"Unsupported argument in 2.0.0" userInfo:nil];
        return nil;
    }
    
    if (![self isNeutered]) {
        return self.keychain.extendedPrivateKey;
    } else {
        return self.keychain.extendedPublicKey;
    }
}

- (HDNode *)derive:(JSValue *)_index
{
    return [[HDNode alloc] initWithKeychain:[self.keychain derivedKeychainAtIndex:[_index toUInt32]]];
}

- (HDNode *)deriveHardened:(JSValue *)_index
{
    return [[HDNode alloc] initWithKeychain:[self.keychain derivedKeychainAtIndex:[_index toUInt32] hardened:YES]];
}

- (HDNode *)derivePath:(JSValue *)_path
{
    return [[HDNode alloc] initWithKeychain:[self.keychain derivedKeychainWithPath:[_path toString]]];
}

- (HDNode *)neutered
{
    return [[HDNode alloc] initWithKeychain:[[BTCKeychain alloc] initWithExtendedKey:self.keychain.extendedPublicKey]];
}

@end

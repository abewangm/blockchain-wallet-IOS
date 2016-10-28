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

@interface HDNode()
@property(nonatomic) NSMutableData* privateKey;
@property(nonatomic) NSMutableData* publicKey;
@end
@implementation HDNode
{
    JSManagedValue *_chainCode;
    JSManagedValue *_keyPair;
    JSManagedValue *_network;
}

@synthesize depth;
@synthesize index;
@synthesize parentFingerprint;

- (void)setKeyPair:(JSValue *)keyPair
{
    _keyPair = [JSManagedValue managedValueWithValue:keyPair];
    [[[JSContext currentContext] virtualMachine] addManagedReference:_keyPair withOwner:self];
}

- (JSValue *)keyPair
{
    return _keyPair.value;
}

- (void)setChainCode:(JSValue *)chainCode
{
    _chainCode = [JSManagedValue managedValueWithValue:chainCode];
    [[[JSContext currentContext] virtualMachine] addManagedReference:_chainCode withOwner:self];
}

- (JSValue *)chainCode
{
    return _chainCode.value;
}

- (id)initWithKeyPair:(JSValue *)keyPair chainCode:(JSValue *)chainCode
{
    if (self = [super init]) {
        self.keyPair = keyPair;
        self.chainCode = chainCode;
        self.depth = 0;
        self.index = 0;
        self.parentFingerprint = 0x00000000;
    }
    return self;
}

+ (HDNode *)fromSeed:(NSString *)seed network:(JSValue *)network
{
    if (!seed) return nil;
    
    NSMutableData* hmac = BTCHMACSHA512([@"Bitcoin seed" dataUsingEncoding:NSASCIIStringEncoding], [seed dataUsingEncoding:NSUTF8StringEncoding]);
    NSData *privateKey = BTCDataRange(hmac, NSMakeRange(0, 32));
    NSData *chainCode  = BTCDataRange(hmac, NSMakeRange(32, 32));
    BTCDataClear(hmac);
    
    NSString *privateKeyString = [privateKey hexadecimalString];
    NSString *chainCodeString = [chainCode hexadecimalString];
    
    JSValue *json = [app.wallet executeJSSynchronous:@"MyWalletPhone.getJSON()"];
    NSString *networkString = [[json invokeMethod:@"stringify" withArguments:@[network]] toString];
    
    JSValue *keyPair = [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new ECPair(BigInteger.fromBuffer(new Buffer('%@', 'hex')), null, {network: %@})", [privateKeyString escapeStringForJS], networkString]];
    JSValue *chainCodeValue = [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", chainCodeString]];
    return [[HDNode alloc] initWithKeyPair:keyPair chainCode:chainCodeValue];
}

- (JSValue *)getAddress
{
    return [self.keyPair invokeMethod:@"getAddress" withArguments:nil];
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
    return [HDNode fromSeed:seed network:networks];
}

- (NSString *)getIdentifier
{
    JSValue *publicKeyBuffer = [self.keyPair invokeMethod:@"getPublicKeyBuffer" withArguments:nil];
    NSMutableData *data = BTCHash160([[publicKeyBuffer toString] dataUsingEncoding:NSUTF8StringEncoding]);
    return [data hexadecimalString];
}

- (JSValue *)getFingerprint
{
    return [[self.keyPair invokeMethod:@"getIdentifier" withArguments:nil] invokeMethod:@"slice" withArguments:@[@0,@4]];
}

- (JSValue *)toBase58:(JSValue *)isPrivate
{
    
}

- (JSValue *)getNetwork
{
    return [self.keyPair invokeMethod:@"getNetwork" withArguments:nil];
}

- (JSValue *)getPublicKeyBuffer
{
    return [self.keyPair invokeMethod:@"getPublicKeyBuffer" withArguments:nil];
}

- (HDNode *)deriveHardened:(JSValue *)_index
{
    uint32_t highestBit = 0x80000000;
    return [self derivedKeychainAtIndex:[_index toUInt32] + highestBit hardened:YES factor:nil];
}

- (HDNode *)derive:(JSValue *)_index
{
    
}

- (BOOL)isNeutered
{
    return ![[self.keyPair valueForProperty:@"d"] toBool];
}

- (HDNode *)derivePath:(JSValue *)path
{
    
}

- (HDNode *) derivedKeychainAtIndex:(uint32_t)index hardened:(BOOL)hardened factor:(BTCBigNumber**)factorOut
{
//    // CHECK_IF_CLEARED;
//    
//    // As we use explicit parameter "hardened", do not allow higher bit set.
//    if ((0x80000000 & index) != 0) {
//        @throw [NSException exceptionWithName:@"BTCKeychain Exception"
//                                       reason:@"Indexes >= 0x80000000 are invalid. Use hardened:YES argument instead." userInfo:nil];
//        return nil;
//    }
//    
//    if (!_privateKey && hardened) {
//        // Not possible to derive hardened keychain without a private key.
//        return nil;
//    }
//    
//    BTCKeychain* derivedKeychain = [[BTCKeychain alloc] init];
//    
//    NSMutableData* data = [NSMutableData data];
//    
//    if (hardened) {
//        uint8_t padding = 0;
//        [data appendBytes:&padding length:1];
//        [data appendData:_privateKey];
//    } else {
//        [data appendData:self.publicKey];
//    }
//    
//    uint32_t indexBE = OSSwapHostToBigInt32(hardened ? (0x80000000 | index) : index);
//    [data appendBytes:&indexBE length:sizeof(indexBE)];
//    
//    NSData* digest = BTCHMACSHA512(_chainCode, data);
//    
//    BTCBigNumber* factor = [[BTCBigNumber alloc] initWithUnsignedBigEndian:[digest subdataWithRange:NSMakeRange(0, 32)]];
//    
//    // Factor is too big, this derivation is invalid.
//    if ([factor greaterOrEqual:[BTCCurvePoint curveOrder]]) {
//        return nil;
//    }
//    
//    if (factorOut) *factorOut = factor;
//    
//    derivedKeychain.chainCode = BTCDataRange(digest, NSMakeRange(32, 32));
//    
//    if (_privateKey) {
//        BTCMutableBigNumber* pkNumber = [[BTCMutableBigNumber alloc] initWithUnsignedBigEndian:_privateKey];
//        [pkNumber add:factor mod:[BTCCurvePoint curveOrder]];
//        
//        // Check for invalid derivation.
//        if ([pkNumber isEqual:[BTCBigNumber zero]]) return nil;
//        
//        NSData* pkData = pkNumber.unsignedBigEndian;
//        derivedKeychain.privateKey = [pkData mutableCopy];
//        
//        BTCDataClear(pkData);
//        [pkNumber clear];
//    } else {
//        BTCCurvePoint* point = [[BTCCurvePoint alloc] initWithData:_publicKey];
//        [point addGeneratorMultipliedBy:factor];
//        
//        // Check for invalid derivation.
//        if ([point isInfinity]) return nil;
//        
//        NSData* pointData = point.data;
//        derivedKeychain.publicKey = [pointData mutableCopy];
//        BTCDataClear(pointData);
//        [point clear];
//    }
//    
//    derivedKeychain.depth = _depth + 1;
//    derivedKeychain.parentFingerprint = self.fingerprint;
//    derivedKeychain.index = index;
//    derivedKeychain.hardened = hardened;
//    
//    return derivedKeychain;
}

@end

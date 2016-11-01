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

#define BTCKeychainTestnetPrivateVersion 0x04358394
#define BTCKeychainTestnetPublicVersion  0x043587CF

@interface HDNode()
@property(nonatomic) NSData* privateKey;
@property(nonatomic) NSData* publicKey;
@end
@implementation HDNode
{
    JSManagedValue *_chainCode;
    JSManagedValue *_keyPair;
}

@synthesize depth;
@synthesize index;
@synthesize parentFingerprint;

- (NSData *)privateKey
{
    return [[[self.keyPair valueForProperty:@"d"] toString] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSData *)publicKey
{
    return [[[self.keyPair valueForProperty:@"Q"] toString] dataUsingEncoding:NSUTF8StringEncoding];
}

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
    NSData *bufferData = BTCDataFromBase58(seed);
    
    if (![app.wallet executeJSSynchronous:[NSString stringWithFormat:@"MyWalletPhone.isBufferDataLengthValid('%@')", [[bufferData hexadecimalString] escapeStringForJS]]]) {
        DLog(@"Invalid buffer length");
        return nil;
    }
    
    const uint8_t* bytes = bufferData.bytes;
    uint32_t version = OSSwapBigToHostInt32(*((uint32_t*)bytes));
    
    JSValue *network;
    BOOL isPrivate;
    if ([[networks toArray] isKindOfClass:[NSArray class]]) {
        NSPredicate *privateOrPublicVersions = [NSPredicate predicateWithBlock:^BOOL(JSValue *value, NSDictionary *bindings) {
            // Inexact match: JS is written with triple equal comparison
            // https://github.com/bitcoinjs/bitcoinjs-lib/blob/4faa0ce679d67b69f0165b73532b34a19757693f/src/hdnode.js#L65-L66
            return version == [[[value valueForProperty:@"bip32"] valueForProperty:@"private"] toUInt32] ||
            version == [[[value valueForProperty:@"bip32"] valueForProperty:@"public"] toUInt32];
        }];
        
        NSArray *filteredNetworks = [[networks toArray] filteredArrayUsingPredicate:privateOrPublicVersions];
        network = [filteredNetworks firstObject];
        isPrivate = version == [[[network valueForProperty:@"bip32"] valueForProperty:@"private"] toUInt32];
        // Inexact match: JS is written with triple equal comparison
        // https://github.com/bitcoinjs/bitcoinjs-lib/blob/4faa0ce679d67b69f0165b73532b34a19757693f/src/hdnode.js#L76-L77
        if (version != [[[network valueForProperty:@"bip32"] valueForProperty:@"private"] toUInt32] ||
            version != [[[network valueForProperty:@"bip32"] valueForProperty:@"public"] toUInt32]) {
            DLog(@"Invalid network version");
        }
    } else {
        // Inexact match: JS is written as
        // https://github.com/bitcoinjs/bitcoinjs-lib/blob/4faa0ce679d67b69f0165b73532b34a19757693f/src/hdnode.js#L73
        // network = networks || NETWORKS.bitcoin
        network = networks;
        // Inexact match: JS is written with triple equal comparison
        // https://github.com/bitcoinjs/bitcoinjs-lib/blob/4faa0ce679d67b69f0165b73532b34a19757693f/src/hdnode.js#L76-L77
        if (version != [[[[[network toArray] firstObject] valueForProperty:@"bip32"] valueForProperty:@"private"] toUInt32] ||
            version != [[[[[network toArray] firstObject] valueForProperty:@"bip32"] valueForProperty:@"public"] toUInt32]) {
            DLog(@"Invalid network version");
        }
        isPrivate = version == [[[[[network toArray] firstObject] valueForProperty:@"bip32"] valueForProperty:@"private"] toUInt32];
    }
    
    return [[HDNode alloc] initWithExtendedKeyDataInternal:bufferData isPrivate:isPrivate];
}

- (NSString *)getIdentifier
{
    JSValue *publicKeyBuffer = [self.keyPair invokeMethod:@"getPublicKeyBuffer" withArguments:nil];
    NSMutableData *data = BTCHash160([[publicKeyBuffer toString] dataUsingEncoding:NSUTF8StringEncoding]);
    return [data hexadecimalString];
}

- (JSValue *)getFingerprint
{
    return [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"'%@'.slice(0,4)", [self getIdentifier]]];
}

- (JSValue *)getNetwork
{
    return [self.keyPair invokeMethod:@"getNetwork" withArguments:nil];
}

- (JSValue *)getPublicKeyBuffer
{
    return [self.keyPair invokeMethod:@"getPublicKeyBuffer" withArguments:nil];
}

- (BOOL)isNeutered
{
    if ([[[self.keyPair valueForProperty:@"d"] toString] isEqualToString:@"undefined"]) return NO;
    return ![self.keyPair valueForProperty:@"d"];
}

- (JSValue *)sign:(JSValue *)hash
{
    return [self.keyPair invokeMethod:@"sign" withArguments:@[hash]];
}

- (JSValue *)verif:(JSValue *)hash y:(JSValue *)signature
{
    return [self.keyPair invokeMethod:@"verify" withArguments:@[hash, signature]];
}

- (JSValue *)toBase58:(JSValue *)isPrivate
{
    if (isPrivate) {
        DLog(@"Unsupported argument in 2.0.0");
        return nil;
    }
    
    JSValue *network = [self.keyPair valueForProperty:@"network"];
    BOOL bip32IsPrivate = YES;
    JSValue *version;
    if ([self isNeutered]) {
        version = [[network valueForProperty:@"bip32"] valueForProperty:@"private"];
    } else {
        version = [[network valueForProperty:@"bip32"] valueForProperty:@"public"];
        bip32IsPrivate = NO;
    }
    NSMutableData *bufferData = BTCDataFromBase58Check([version toString]);
    NSString *dataString = BTCBase58StringWithData(bufferData);
    return [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", dataString]];
}

- (id) initWithExtendedKeyDataInternal:(NSData*)extendedKeyData isPrivate:(BOOL)isPrivate
{
    if (self = [super init]) {
        if (extendedKeyData.length != 78) return nil;
        
        const uint8_t* bytes = extendedKeyData.bytes;
        uint32_t version = OSSwapBigToHostInt32(*((uint32_t*)bytes));
        
        uint32_t keyprefix = bytes[45];
        
        if (isPrivate) {
            // Should have 0-prefixed private key (1 + 32 bytes).
            if (keyprefix != 0) return nil;
            _privateKey = BTCDataRange(extendedKeyData, NSMakeRange(46, 32));
        } else if (!isPrivate) {
            // Should have a 33-byte public key with non-zero first byte.
            if (keyprefix == 0) return nil;
            _publicKey = BTCDataRange(extendedKeyData, NSMakeRange(45, 33));
        } else {
            // Unknown version.
            return nil;
        }
        
        // If it's a testnet key, remember the network.
        // Otherwise, keep it nil so we don't do extra work if it's not needed.
        if (version == BTCKeychainTestnetPrivateVersion ||
            version == BTCKeychainTestnetPublicVersion) {
            // Testnet not yet implemented on HDNode.js
        }
        
        self.depth = *(bytes + 4);
        self.parentFingerprint = OSSwapBigToHostInt32(*((uint32_t*)(bytes + 5)));
        self.index = OSSwapBigToHostInt32(*((uint32_t*)(bytes + 9)));
        
        if ((0x80000000 & self.index) != 0) {
            self.index = (~0x80000000) & self.index;
            // _hardened = YES;
        }
        
        NSData *chainCodeData = BTCDataRange(extendedKeyData,NSMakeRange(13, 32));
        self.chainCode = [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", [chainCodeData hexadecimalString]]];
    }
    return self;
}

- (HDNode *)derive:(JSValue *)_index
{
    return [self derivedKeychainAtIndex:[_index toUInt32] hardened:NO factor:nil];
}

- (HDNode *)deriveHardened:(JSValue *)_index
{
    return [self derivedKeychainAtIndex:0 hardened:YES factor:nil];
}

- (HDNode *)derivePath:(JSValue *)_path
{
    NSString *path = [_path toString];
    
    if (path == nil) return nil;
    
    if ([path isEqualToString:@"m"] ||
        [path isEqualToString:@"/"] ||
        [path isEqualToString:@""]) {
        return self;
    }
    
    HDNode* hdNode = self;
    
    if ([path rangeOfString:@"m/"].location == 0) { // strip "m/" from the beginning.
        path = [path substringFromIndex:2];
    }
    for (NSString* chunk in [path componentsSeparatedByString:@"/"]) {
        if (chunk.length == 0) {
            continue;
        }
        BOOL hardened = NO;
        NSString* indexString = chunk;
        if ([chunk rangeOfString:@"'"].location == chunk.length - 1) {
            hardened = YES;
            indexString = [chunk substringToIndex:chunk.length - 1];
        }
        
        // Make sure the chunk is just a number
        NSInteger i = [indexString integerValue];
        if (i >= 0 && [@(i).stringValue isEqualToString:indexString]) {
            hdNode = [hdNode derivedKeychainAtIndex:(uint32_t)i hardened:hardened factor:nil];
        } else {
            return nil;
        }
    }
    return hdNode;
}

- (HDNode *)derivedKeychainAtIndex:(uint32_t)_index hardened:(BOOL)hardened factor:(BTCBigNumber**)factorOut
{
    // CHECK_IF_CLEARED;
    
    // As we use explicit parameter "hardened", do not allow higher bit set.
    if ((0x80000000 & _index) != 0) {
        @throw [NSException exceptionWithName:@"BTCKeychain Exception"
                                       reason:@"Indexes >= 0x80000000 are invalid. Use hardened:YES argument instead." userInfo:nil];
        return nil;
    }
    
    if ([self isNeutered] && hardened) {
        DLog(@"Not possible to derive hardened keychain without a private key.");
        return nil;
    }
    
    JSValue *derivedKeypair;
    
    NSMutableData* data = [NSMutableData data];
    
    if (hardened) {
        uint8_t padding = 0;
        [data appendBytes:&padding length:1];
        [data appendData:[self privateKey]];
    } else {
        [data appendData:[self publicKey]];
    }
    
    uint32_t indexBE = OSSwapHostToBigInt32(hardened ? (0x80000000 | index) : index);
    [data appendBytes:&indexBE length:sizeof(indexBE)];
    
    NSData* digest = BTCHMACSHA512([[self.chainCode toString] dataUsingEncoding:NSUTF8StringEncoding], data);
    
    BTCBigNumber* factor = [[BTCBigNumber alloc] initWithUnsignedBigEndian:[digest subdataWithRange:NSMakeRange(0, 32)]];
    
    // Factor is too big, this derivation is invalid.
    if ([factor greaterOrEqual:[BTCCurvePoint curveOrder]]) {
        return [self derive:[JSValue valueWithInt32:(_index + 1) inContext:app.wallet.context]];
    }
    
    if (factorOut) *factorOut = factor;
    
    NSData *chainCode = BTCDataRange(digest, NSMakeRange(32, 32));
    
    JSValue *network = [self.keyPair valueForProperty:@"network"];
    JSValue *json = [app.wallet executeJSSynchronous:@"MyWalletPhone.getJSON()"];
    NSString *networkString = [[json invokeMethod:@"stringify" withArguments:@[network]] toString];
    
    if (![self isNeutered]) {
        BTCMutableBigNumber* pkNumber = [[BTCMutableBigNumber alloc] initWithUnsignedBigEndian:[self privateKey]];
        [pkNumber add:factor mod:[BTCCurvePoint curveOrder]];
        
        // Check for invalid derivation.
        if ([pkNumber isEqual:[BTCBigNumber zero]]) {
            return [self derive:[JSValue valueWithInt32:(_index + 1) inContext:app.wallet.context]];
        }
        
        NSData* pkData = pkNumber.unsignedBigEndian;
        
        derivedKeypair = [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new ECPair(BigInteger.fromBuffer(new Buffer('%@', 'hex')), null, {network: %@})", [[[pkData mutableCopy] hexadecimalString] escapeStringForJS], networkString]];
        
        BTCDataClear(pkData);
        [pkNumber clear];
    } else {
        BTCCurvePoint* point = [[BTCCurvePoint alloc] initWithData:[self publicKey]];
        [point addGeneratorMultipliedBy:factor];
        
        // Check for invalid derivation.
        if ([point isInfinity]) {
            return [self derive:[JSValue valueWithInt32:(_index + 1) inContext:app.wallet.context]];
        }
        
        JSValue *curveG = [app.wallet executeJSSynchronous:@"Ecurve.getCurveByName('secp256k1').G"];
        JSValue *pIL = [app.wallet executeJSSynchronous:[NSString stringWithFormat:@"BigInteger.fromBuffer(new Buffer('%@', 'hex'))", [[[digest subdataWithRange:NSMakeRange(0, 32)] hexadecimalString] escapeStringForJS]]];
        JSValue *multiplyResult = [curveG invokeMethod:@"multiply" withArguments:@[pIL]];
        JSValue *addResult = [multiplyResult invokeMethod:@"add" withArguments:@[[self.keyPair valueForProperty:@"Q"]]];
        JSValue *ecPair = [app.wallet executeJSSynchronous:@"MyWalletPhone.newPublicECPairObject"];
        
        derivedKeypair = [ecPair callWithArguments:@[addResult, network]];
        [point clear];
    }
    
    HDNode *newHDNode = [[HDNode alloc] initWithKeyPair:derivedKeypair chainCode:[app.wallet executeJSSynchronous:[NSString stringWithFormat:@"new Buffer('%@', 'hex')", [chainCode hexadecimalString]]]];
    newHDNode.depth = self.depth + 1;
    
    // It is unclear which encoding to use here
    const uint8_t* bytes = [[[self getFingerprint] toString] dataUsingEncoding:NSUTF8StringEncoding].bytes;
    uint32_t readValue = OSSwapBigToHostInt32(*((uint32_t*)bytes));
    newHDNode.parentFingerprint = readValue;
//    newHDNode.parentFingerprint = [[[[self getFingerprint] invokeMethod:@"readUInt32BE" withArguments:@[@0]] toNumber] intValue];
    newHDNode.index = index;
    // newHDNode.hardened = hardened;
    
    return newHDNode;
}

@end

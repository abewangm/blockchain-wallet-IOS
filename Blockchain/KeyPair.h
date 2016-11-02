//
//  KeyPair.h
//  Blockchain
//
//  Created by Kevin Wu on 11/2/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
@class BTCKey, KeyPair;

@protocol ExportKeyPair <JSExport>
@property (nonatomic, readonly) JSValue *d;
@property (nonatomic, readonly) JSValue *Q;
@property (nonatomic, readonly) JSValue *network;

+ (KeyPair *)fromPublicKey:(NSString *)buffer buffer:(JSValue *)network;
+ (KeyPair *)from:(NSString *)string WIF:(JSValue *)network;
+ (KeyPair *)makeRandom:(JSValue *)options;

- (NSString *)getAddress;
- (JSValue *)getPublicKeyBuffer;
- (JSValue *)sign:(JSValue *)hash;
- (NSString *)toWIF;

// Cannot override this function without changing its name in the JS because its # of capital letters is less than the # of parameters. To override <verify> as below, <verify> would have to be changed to <verifY> because JavaScriptCore camel-cases between parameters. Alternatively, <verify:(JSValue *)args> may be used if the function can be changed in the JS to take only one parameter containing the others.
- (KeyPair *)verif:(NSString *)hash y:(NSString *)signature;
@end

@interface KeyPair : NSObject <ExportKeyPair>
@property (nonatomic) BTCKey *key;
- (id)initWithKey:(BTCKey *)key network:(JSValue *)network;
@end

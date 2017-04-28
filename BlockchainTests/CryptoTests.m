//
//  CryptoTests.m
//  Blockchain
//
//  Created by kevinwu on 3/2/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "Wallet.h"
#import "NSString+NSString_EscapeQuotes.h"
#import <JavaScriptCore/JavaScriptCore.h>
#import "NSData+Hex.h"
#import "Blockchain-Prefix.pch"
#import "TestAccounts.h"
#import "RootService.h"

@interface CryptoTests : XCTestCase
@property (nonatomic) Wallet *wallet;
@end

@implementation CryptoTests

- (void)setUp {
    [super setUp];
    
    self.wallet = [[Wallet alloc] init];
    [self.wallet loadWalletWithGuid:nil sharedKey:nil password:nil];
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testStretchPassword {
    
    NSString *stretched = [self stretchPassword:@"1234567890" salt:@"a633e05b567f64482d7620170bd45201" pbkdf2Iterations:10];
    XCTAssertEqualObjects(stretched, @"4be158806522094dd184bc9c093ea185c6a4ec003bdc6323108e3f5eeb7e388d");
}

- (void)testCryptoScrypt {
    
    __block NSString *computedString;
    NSString *expectedString = @"f890a6beae1dc3f627f9d9bcca8a96950b11758beb1edf1b072c8b8522d155629db68aba34619e1ae45b4b6b2917bcb8fd1698b536124df69d5c36d7f28fbe0e";
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"result"];
    
    self.wallet.context[@"test_crypto_scrypt_success"] = ^(JSValue *buffer) {
        computedString = [[buffer invokeMethod:@"toString" withArguments:@[@"hex"]] toString];
        XCTAssertEqualObjects(computedString, expectedString, @"Strings must be equal");
        [expectation fulfill];
    };
    
    NSString *callback = @"function(data) {test_crypto_scrypt_success(data);}";
    
    NSString *script = [NSString stringWithFormat:@"WalletCrypto.scrypt('%@', '%@', %@, %@, %@, %@, %@)", @"ϓ␀𐐀💩", @"ϓ␀𐐀💩", @64, @2, @2, @64, callback];
    [self.wallet.context evaluateScript:script];
    
    [self waitForExpectationsWithTimeout:5 handler:^(NSError * _Nullable error) {
        [app hideBusyView];
    }];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

#pragma mark - Helpers

- (NSString *)stretchPassword:(NSString *)password salt:(NSString *)salt pbkdf2Iterations:(int)iterations
{
    return [[self.wallet executeJSSynchronous:[NSString stringWithFormat:@"WalletCrypto.stretchPassword('%@', new Buffer('%@', 'hex'), %d).toString('hex')", [password escapeStringForJS], [salt escapeStringForJS], iterations]] toString];
}

@end

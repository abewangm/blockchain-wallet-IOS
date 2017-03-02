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

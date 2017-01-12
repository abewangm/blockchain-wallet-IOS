//
//  BlockchainTests.m
//  BlockchainTests
//
//  Created by Kevin Wu on 4/14/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KIFUITestActor+Login.h"
#import "LocalizationConstants.h"

@interface BlockchainTests : XCTestCase

@end

@implementation BlockchainTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

- (void)testExample {
//    [tester goToSend];
//    [tester typeInAddress];
//    
//    [tester confirmSendAmountDecimalPeriod];
//    [tester confirmSendAmountDecimalComma];
//    [tester confirmSendAmountDecimalArabicComma];
    
    [tester goToReceive];
    
    NSString *randomAmountPeriod = [self getRandomReceiveAmount];
    uint64_t decimalResult = [tester confirmReceiveAmount:randomAmountPeriod];
    uint64_t computedDecimalResult = [tester computeBitcoinValue:randomAmountPeriod];
    XCTAssertEqual(decimalResult, computedDecimalResult, @"Decimal result must be equal");
    
    NSString *randomAmountComma = [self getRandomReceiveAmount];
    uint64_t commaResult = [tester confirmReceiveAmount:[randomAmountComma stringByReplacingOccurrencesOfString:@"." withString:@","]];
    uint64_t computedCommaResult = [tester computeBitcoinValue:randomAmountComma];
    XCTAssertEqual(commaResult, computedCommaResult, @"Comma result must be equal");
    
    NSString *randomAmountArabicComma = [self getRandomReceiveAmount];
    uint64_t arabicCommaResult = [tester confirmReceiveAmount:[randomAmountArabicComma stringByReplacingOccurrencesOfString:@"." withString:@"٫"]];
    uint64_t computedArabicCommaResult = [tester computeBitcoinValue:randomAmountArabicComma];
    XCTAssertEqual(arabicCommaResult, computedArabicCommaResult, @"Arabic comma result must be equal");
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

#pragma mark - Helpers

- (NSString *)getRandomReceiveAmount
{
    float randomNumber = ((float)arc4random() / 0x100000000 * (100 - 0.01)) + 0.01;
    return [NSString stringWithFormat:@"%.2f", randomNumber];
}

@end

//
//  ReceiveTests.m
//  Blockchain
//
//  Created by kevinwu on 3/14/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KIFUITestActor+Login.h"
#import "LocalizationConstants.h"
#import "Blockchain-Prefix.pch"

@interface ReceiveTests : XCTestCase

@end

@implementation ReceiveTests

- (void)setUp {
    [super setUp];
    // Put setup code here. This method is called before the invocation of each test method in the class.
    if ([[[UIApplication sharedApplication] keyWindow] accessibilityElementWithLabel:ACCESSIBILITY_LABEL_CREATE_NEW_WALLET] != nil) {
        [tester createNewWallet];
    } else if ([[[UIApplication sharedApplication] keyWindow] accessibilityElementWithLabel:ACCESSIBILITY_LABEL_FORGET_WALLET] != nil) {
        [tester forgetWallet];
    } else {
        [tester enterPIN];
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [tester logoutAndForgetWallet];

    [super tearDown];
}

- (void)testReceiveAmounts {
    
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

#pragma mark - Helpers

- (NSString *)getRandomReceiveAmount
{
    float randomNumber = ((float)arc4random() / 0x100000000 * (100 - 0.01)) + 0.01;
    return [NSString stringWithFormat:@"%.2f", randomNumber];
}

@end

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
#import "Blockchain-Prefix.pch"
#import "TestAccounts.h"
#import "RootService.h"

@interface BlockchainTests : XCTestCase

@end

@implementation BlockchainTests

- (void)setUp {
    [super setUp];
    
    [tester waitForTimeInterval:1];
    
    if ([tester tryFindingViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_CREATE_NEW_WALLET error:nil]) {
        // Good to go
    } else if ([tester tryFindingViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_FORGET_WALLET error:nil]) {
        [tester forgetWallet];
        [tester createNewWallet];
    } else {
        [tester enterPIN];
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
}

@end

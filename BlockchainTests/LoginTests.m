//
//  LoginTests.m
//  Blockchain
//
//  Created by kevinwu on 2/28/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KIFUITestActor+Login.h"
#import "LocalizationConstants.h"
#import "Blockchain-Prefix.pch"
#import "TestAccounts.h"

@interface LoginTests : XCTestCase

@end

@implementation LoginTests

- (void)setUp {
    [super setUp];
    
    [tester waitForTimeInterval:1];
    
    if ([tester tryFindingViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_CREATE_NEW_WALLET error:nil]) {
        // Good to go
    } else if ([tester tryFindingViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_FORGET_WALLET error:nil]) {
        [tester forgetWallet];
    } else {
        [tester enterPIN];
        [tester logoutAndForgetWallet];
    }
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    if ([tester tryFindingViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_CREATE_NEW_WALLET error:nil]) {
        // Good to go
    } else if ([tester tryFindingViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_FORGET_WALLET error:nil]) {
        [tester forgetWallet];
    } else {
        [tester logoutAndForgetWallet];
    }
}

- (void)testCreateWallet
{
    [tester createNewWallet];
}

- (void)testLoginExistingWallet {
    
    [tester manualPairWithGUID:GUID_EMPTY_WALLET password:PASSWORD_EMPTY_WALLET];
}

@end

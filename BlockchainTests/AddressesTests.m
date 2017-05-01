//
//  AddressesTests.m
//  Blockchain
//
//  Created by kevinwu on 3/14/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KIFUITestActor+Login.h"
#import "LocalizationConstants.h"
#import "Blockchain-Prefix.pch"

@interface AddressesTests : XCTestCase

@end

@implementation AddressesTests

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

- (void)testCreateAccount {
    
    [tester goToAddresses];
    [tester createAccount];
}

@end

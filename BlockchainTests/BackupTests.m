//
//  BackupTests.m
//  Blockchain
//
//  Created by kevinwu on 3/3/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <XCTest/XCTest.h>
#import "KIFUITestActor+Login.h"
#import "LocalizationConstants.h"
#import "Blockchain-Prefix.pch"
#import "TestAccounts.h"
#import "RootService.h"

@interface BackupTests : XCTestCase

@end

@implementation BackupTests

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
    
    [tester createNewWallet];

}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
    [super tearDown];
    
    [tester logoutAndForgetWallet];
}

- (void)testBackupFromSideMenuOfEmptyWallet {
    
    [tester backupFromSideMenu];
    
    XCTAssertTrue(app.wallet.isRecoveryPhraseVerified, @"Wallet should have completed backup");
    
    [tester closeSideMenuNavigationController];
}

- (void)testPerformanceExample {
    // This is an example of a performance test case.
    [self measureBlock:^{
        // Put the code you want to measure the time of here.
    }];
}

@end

//
//  KIFUITestActor+Login.m
//  Blockchain
//
//  Created by Kevin Wu on 4/14/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import "KIFUITestActor+Login.h"
#import "LocalizationConstants.h"

@implementation KIFUITestActor (Login)

- (void)createNewWallet
{
    [self waitForTappableViewWithAccessibilityLabel:BC_STRING_CREATE_NEW_WALLET];
    [self tapViewWithAccessibilityLabel:BC_STRING_CREATE_NEW_WALLET];
    
    [self waitForTappableViewWithAccessibilityLabel:BC_STRING_CREATE_WALLET];
    [self tapViewWithAccessibilityLabel:BC_STRING_CREATE_WALLET];
}

- (void)enterPIN
{
    [self waitForViewWithAccessibilityLabel:BC_STRING_DID_CREATE_NEW_WALLET_TITLE];
    [self waitForViewWithAccessibilityLabel:BC_STRING_DID_CREATE_NEW_WALLET_DETAIL];
    [self waitForTappableViewWithAccessibilityLabel:BC_STRING_OK];
    [self tapViewWithAccessibilityLabel:BC_STRING_OK];
}

@end

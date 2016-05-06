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

- (void)send
{
    [self waitForTappableViewWithAccessibilityLabel:BC_STRING_SEND];
    [self tapViewWithAccessibilityLabel:BC_STRING_SEND];
    [self waitForTappableViewWithAccessibilityLabel:BC_STRING_SELECT_ADDRESS];
    [self tapViewWithAccessibilityLabel:BC_STRING_SELECT_ADDRESS];
    [self enterTextIntoCurrentFirstResponder:@"1MdLTHM5xTNuu7D12fyce5MqtchnRmuijq"];
    [self tapViewWithAccessibilityLabel:BC_STRING_AMOUNT_FIELD];
    [self enterTextIntoCurrentFirstResponder:@"0.05"];
    [self waitForAnimationsToFinish];
    [self tapViewWithAccessibilityLabel:BC_STRING_SEND_BUTTON];
    [self waitForTappableViewWithAccessibilityLabel:BC_STRING_CONFIRM_SEND_BUTTON];
    [self tapViewWithAccessibilityLabel:BC_STRING_CONFIRM_SEND_BUTTON];
    [self waitForTappableViewWithAccessibilityLabel:BC_STRING_TRANSACTION];
}

@end

//
//  KIFUITestActor+Login.m
//  Blockchain
//
//  Created by Kevin Wu on 4/14/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import "KIFUITestActor+Login.h"
#import "Blockchain-Prefix.pch"
#import "RootService.h"

@implementation KIFUITestActor (Login)

- (void)createNewWallet
{
    [self waitForTappableViewWithAccessibilityLabel:BC_STRING_CREATE_NEW_WALLET];
    [self tapViewWithAccessibilityLabel:BC_STRING_CREATE_NEW_WALLET];
    
    [self waitForTappableViewWithAccessibilityLabel:BC_STRING_CREATE_WALLET];
    [self tapViewWithAccessibilityLabel:BC_STRING_CREATE_WALLET];
}

#pragma mark - Send

- (void)send
{
    [self goToSend];
    [self typeInAddress];
    
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_SEND_FIAT_FIELD];
    [self enterTextIntoCurrentFirstResponder:@"0.10"];
    [self waitForAnimationsToFinish];
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_CONTINUE_PAYMENT];
    [self waitForTappableViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_CONFIRM_PAYMENT];
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_CONFIRM_PAYMENT];
}

- (void)goToSend
{
    [self waitForTappableViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_SEND_TAB];
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_SEND_TAB];
}

- (void)typeInAddress
{
    [self waitForTappableViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_SELECT_ADDRESS];
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_SELECT_ADDRESS];
    [self enterTextIntoCurrentFirstResponder:@"1MdLTHM5xTNuu7D12fyce5MqtchnRmuijq"];
}

// Period separator

- (void)confirmSendAmountDecimalPeriodDecimalFirst
{
    [self confirmSendAmountWithText:@".10"];
}

- (void)confirmSendAmountDecimalPeriodZeroThenDecimal
{
    [self confirmSendAmountWithText:@"0.10"];
}

- (void)confirmSendAmountDecimalPeriodNumberThenDecimal
{
    [self confirmSendAmountWithText:@"1.10"];
}

- (void)confirmSendAmountDecimalPeriodArabicTextDecimalFirst
{
    [self confirmSendAmountWithText:@".١٠"];
}

- (void)confirmSendAmountDecimalPeriodArabicTextZeroThenDecimal
{
    [self confirmSendAmountWithText:@"٠.١٠"];
}

- (void)confirmSendAmountDecimalPeriodArabicTextNumberThenDecimal
{
    [self confirmSendAmountWithText:@"١.١٠"];
}

// Comma separator

- (void)confirmSendAmountDecimalCommaDecimalFirst
{
    [self confirmSendAmountWithText:@",10"];
}

- (void)confirmSendAmountDecimalCommaZeroThenDecimal
{
    [self confirmSendAmountWithText:@"0,10"];
}

- (void)confirmSendAmountDecimalCommaNumberThenDecimal
{
    [self confirmSendAmountWithText:@"1,10"];
}

- (void)confirmSendAmountDecimalCommaArabicTextDecimalFirst
{
    [self confirmSendAmountWithText:@",١٠"];
}

- (void)confirmSendAmountDecimalCommaArabicTextZeroThenDecimal
{
    [self confirmSendAmountWithText:@"٠,١٠"];
}

- (void)confirmSendAmountDecimalCommaArabicTextNumberThenDecimal
{
    [self confirmSendAmountWithText:@"١,١٠"];
}

// Arabic Comma separator

- (void)confirmSendAmountDecimalArabicCommaDecimalFirst
{
    [self confirmSendAmountWithText:@"٫10"];
}

- (void)confirmSendAmountDecimalArabicCommaZeroThenDecimal
{
    [self confirmSendAmountWithText:@"0٫10"];
}

- (void)confirmSendAmountDecimalArabicCommaNumberThenDecimal
{
    [self confirmSendAmountWithText:@"1٫10"];
}

- (void)confirmSendAmountDecimalArabicCommaAndTextDecimalFirst
{
    [self confirmSendAmountWithText:@"٫١٠"];
}

- (void)confirmSendAmountDecimalArabicCommaAndTextZeroThenDecimal
{
    [self confirmSendAmountWithText:@"٠٫١٠"];
}

- (void)confirmSendAmountDecimalArabicCommaAndTextNumberThenDecimal
{
    [self confirmSendAmountWithText:@"١٫١٠"];
}

- (void)confirmSendAmountWithText:(NSString *)text
{
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_SEND_FIAT_FIELD];
    [self enterTextIntoCurrentFirstResponder:text];
    [self waitForAnimationsToFinish];
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_CONTINUE_PAYMENT];
    [self waitForTappableViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_MODAL_BACK_CHEVRON];
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_MODAL_BACK_CHEVRON];
    [self clearTextFromViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_SEND_FIAT_FIELD];
}

#pragma mark - Receive

- (void)goToReceive
{
    [self waitForTappableViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_RECEIVE_TAB];
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_RECEIVE_TAB];
}

- (uint64_t)confirmReceiveAmount:(NSString *)randomAmount
{
    [self tapViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_RECEIVE_FIAT_FIELD];
    [self clearTextFromViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_RECEIVE_FIAT_FIELD_INPUT_ACCESSORY];
    [self enterTextIntoCurrentFirstResponder:randomAmount];
    [self waitForAnimationsToFinish];
    
    UITextField *textField = (UITextField *)[self waitForViewWithAccessibilityLabel:ACCESSIBILITY_LABEL_RECEIVE_FIAT_FIELD];
    return [app.wallet parseBitcoinValueFromTextField:textField];
}

- (uint64_t)computeBitcoinValue:(NSString *)amount
{
    return [app.wallet parseBitcoinValueFromString:amount];
}

@end

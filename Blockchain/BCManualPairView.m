//
//  ManualPairView.m
//  Blockchain
//
//  Created by Mark Pfluger on 9/25/14.
//  Copyright (c) 2014 Qkos Services Ltd. All rights reserved.
//

#import "BCManualPairView.h"
#import "AppDelegate.h"

@implementation BCManualPairView

- (void)awakeFromNib
{
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = CGRectMake(0, 0, self.window.frame.size.width, 46);
    saveButton.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [saveButton setTitle:BC_STRING_CONTINUE forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    saveButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
    
    [saveButton addTarget:self action:@selector(continueClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    walletIdentifierTextField.inputAccessoryView = saveButton;
    passwordTextField.inputAccessoryView = saveButton;
}

- (void)prepareForModalPresentation
{
    walletIdentifierTextField.delegate = self;
    passwordTextField.delegate = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [walletIdentifierTextField becomeFirstResponder];
    });
    
    // Get the session id SID from the server
    [app.wallet loadWalletLogin];
}

- (void)prepareForModalDismissal
{
    walletIdentifierTextField.delegate = nil;
    passwordTextField.delegate = nil;
}

- (void)clearTextFields
{
    walletIdentifierTextField.text = nil;
    passwordTextField.text = nil;
}

- (void)clearPasswordTextField
{
    passwordTextField.text = nil;
}

- (void)modalWasDismissed
{
    [self clearPasswordTextField];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == walletIdentifierTextField) {
        [passwordTextField becomeFirstResponder];
    }
    else if (textField == verifyTwoFactorTextField) {
        app.wallet.twoFactorInput = textField.text;
        [self continueClicked:textField];
    } else {
        [self continueClicked:textField];
    }
    
    return YES;
}

- (IBAction)continueClicked:(id)sender
{
    NSString *guid = walletIdentifierTextField.text;
    NSString *password = passwordTextField.text;
    
    if ([guid length] != 36) {
        [app standardNotify:BC_STRING_ENTER_YOUR_CHARACTER_WALLET_IDENTIFIER title:BC_STRING_INVALID_IDENTIFIER delegate:nil];
        
        [walletIdentifierTextField becomeFirstResponder];
        
        return;
    }
    
    if (password.length == 0) {
        [app standardNotify:BC_STRING_NO_PASSWORD_ENTERED];
        
        [passwordTextField becomeFirstResponder];
        
        return;
    }
    
    if (![app checkInternetConnection]) {
        return;
    }
    
    [walletIdentifierTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
        
    [app.wallet loadWalletWithGuid:guid sharedKey:nil password:password];
    
    app.wallet.delegate = app;
}

- (void)verifyTwoFactorSMS
{
    UIAlertController *alertForVerifyingMobileNumber = [UIAlertController alertControllerWithTitle:BC_STRING_SETTINGS_VERIFY_ENTER_CODE message:BC_STRING_ENTER_TWO_FACTOR_CODE preferredStyle:UIAlertControllerStyleAlert];
    [alertForVerifyingMobileNumber addAction:[UIAlertAction actionWithTitle:BC_STRING_SETTINGS_VERIFY style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        app.wallet.twoFactorInput = [[alertForVerifyingMobileNumber textFields] firstObject].text;
        [self continueClicked:nil];
    }]];
    [alertForVerifyingMobileNumber addAction:[UIAlertAction actionWithTitle:BC_STRING_SETTINGS_VERIFY_MOBILE_RESEND style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [app.wallet resendTwoFactorSMS];
    }]];
    [alertForVerifyingMobileNumber addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [alertForVerifyingMobileNumber addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        verifyTwoFactorTextField = (BCSecureTextField *)textField;
        verifyTwoFactorTextField.autocapitalizationType = UITextAutocapitalizationTypeNone;
        verifyTwoFactorTextField.autocorrectionType = UITextAutocorrectionTypeNo;
        verifyTwoFactorTextField.spellCheckingType = UITextSpellCheckingTypeNo;
        verifyTwoFactorTextField.delegate = self;
        verifyTwoFactorTextField.returnKeyType = UIReturnKeyDone;
        verifyTwoFactorTextField.placeholder = BC_STRING_ENTER_VERIFICATION_CODE;
    }];
    [app.window.rootViewController presentViewController:alertForVerifyingMobileNumber animated:YES completion:nil];
}

@end

//
//  NewAccountView.m
//  Blockchain
//
//  Created by Ben Reeves on 18/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "BCCreateWalletView.h"

#import "AppDelegate.h"

@implementation BCCreateWalletView

- (void)awakeFromNib
{
    UIButton *createButton = [UIButton buttonWithType:UIButtonTypeCustom];
    createButton.frame = CGRectMake(0, 0, self.window.frame.size.width, 46);
    createButton.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [createButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    createButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
    self.createButton = createButton;
    
    emailTextField.inputAccessoryView = createButton;
    passwordTextField.inputAccessoryView = createButton;
    password2TextField.inputAccessoryView = createButton;
    
    passwordTextField.textColor = [UIColor grayColor];
    password2TextField.textColor = [UIColor grayColor];
    
    passwordFeedbackLabel.adjustsFontSizeToFitWidth = YES;
    
    // If loadBlankWallet is called without a delay, app.wallet will still be nil
    [self performSelector:@selector(createBlankWallet) withObject:nil afterDelay:0.1f];
}

- (void)setIsRecoveringWallet:(BOOL)isRecoveringWallet
{
    _isRecoveringWallet = isRecoveringWallet;
    
    if (self.isRecoveringWallet) {
        [self.createButton addTarget:self action:@selector(showRecoveryPhraseView:) forControlEvents:UIControlEventTouchUpInside];
        [self.createButton setTitle:BC_STRING_RECOVER_WALLET forState:UIControlStateNormal];
    } else {
        [self.createButton addTarget:self action:@selector(createAccountClicked:) forControlEvents:UIControlEventTouchUpInside];
        [self.createButton setTitle:BC_STRING_CREATE_WALLET forState:UIControlStateNormal];
    }
}

- (void)createBlankWallet
{
    [app.wallet loadBlankWallet];
}

- (void)didMoveToWindow
{
    [emailTextField becomeFirstResponder];
}

- (void)prepareForModalPresentation
{
    emailTextField.delegate = self;
    passwordTextField.delegate = self;
    password2TextField.delegate = self;
    recoveryPassphraseTextField.delegate = self;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Scroll up to fit all entry fields on small screens
        if (!IS_568_SCREEN) {
            CGRect frame = self.frame;
            
            frame.origin.y = -SCROLL_HEIGHT_SMALL_SCREEN;
            
            self.frame = frame;
        }
        
        [emailTextField becomeFirstResponder];
    });
}

- (void)prepareForModalDismissal
{
    emailTextField.delegate = nil;
    passwordTextField.delegate = nil;
    password2TextField.delegate = nil;
}

- (void)clearPasswordTextFields
{
    passwordTextField.text = nil;
    password2TextField.text = nil;
    passwordStrengthMeter.progress = 0;
    
    passwordTextField.layer.borderColor = COLOR_TEXT_FIELD_BORDER_GRAY.CGColor;
    passwordFeedbackLabel.text = BC_STRING_PASSWORD_MINIMUM_10_CHARACTERS;
    passwordFeedbackLabel.textColor = [UIColor darkGrayColor];
}

- (void)modalWasDismissed
{
    [self clearPasswordTextFields];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    if (textField == emailTextField) {
        [passwordTextField becomeFirstResponder];
    }
    else if (textField == passwordTextField) {
        [password2TextField becomeFirstResponder];
    }
    else if (textField == password2TextField) {
        if (self.isRecoveringWallet) {
            [self showRecoveryPhraseView:nil];
        } else {
            [self createAccountClicked:textField];
        }
    }
    else if (textField == recoveryPassphraseTextField) {
        [self recoverWalletClicked:textField];
    }
    
    return YES;
}

- (IBAction)showRecoveryPhraseView:(id)sender
{
    if (![self isReadyToSubmitForm]) {
        return;
    };
    
    [self closeKeyboard];
    
    [app showModalWithContent:self.recoveryPhraseView closeType:ModalCloseTypeBack headerText:BC_STRING_RECOVER_WALLET onDismiss:^{
        [self.createButton removeTarget:self action:@selector(recoverWalletClicked:) forControlEvents:UIControlEventTouchUpInside];
    } onResume:^{
        [recoveryPassphraseTextField performSelector:@selector(becomeFirstResponder) withObject:nil afterDelay:0.3f];
    }];
    
    [self.createButton removeTarget:self action:@selector(showRecoveryPhraseView:) forControlEvents:UIControlEventTouchUpInside];
    [self.createButton addTarget:self action:@selector(recoverWalletClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    recoveryPassphraseTextField.inputAccessoryView = self.createButton;
}

- (IBAction)recoverWalletClicked:(id)sender
{
    if (self.isRecoveringWallet) {
        NSMutableString *recoveryPhrase = [[NSMutableString alloc] initWithString:recoveryPassphraseTextField.text];
        NSInteger numberOfSpaces = [recoveryPhrase replaceOccurrencesOfString:@" " withString:@"space" options:NSLiteralSearch range:NSMakeRange(0, [recoveryPhrase length])];
        if (numberOfSpaces != RECOVERY_PHRASE_NUMBER_OF_WORDS - 1) {
            [app standardNotify:BC_STRING_RECOVERY_PHRASE_INSTRUCTIONS];
            return;
        }
    }
    
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_RECOVERING_WALLET];
    [app.wallet recoverWithEmail:emailTextField.text password:passwordTextField.text passphrase:recoveryPassphraseTextField.text];
    
    app.wallet.delegate = app;
}


// Get here from New Account and also when manually pairing
- (IBAction)createAccountClicked:(id)sender
{
    if (![self isReadyToSubmitForm]) {
        return;
    };
    
    [self closeKeyboard];
    
    // Load the JS without a wallet
    [app.wallet loadBlankWallet];
    
    // Get callback when wallet is done loading
    // Continue in walletJSReady callback
    app.wallet.delegate = self;
}

- (BOOL)isReadyToSubmitForm
{
    if ([emailTextField.text length] == 0) {
        [app standardNotify:BC_STRING_PLEASE_PROVIDE_AN_EMAIL_ADDRESS];
        [emailTextField becomeFirstResponder];
        return NO;
    }
    
    if ([emailTextField.text rangeOfString:@"@"].location == NSNotFound) {
        [app standardNotify:BC_STRING_INVALID_EMAIL_ADDRESS];
        [emailTextField becomeFirstResponder];
        return NO;
    }
    
    self.tmpPassword = passwordTextField.text;
    
    if ([self.tmpPassword length] < 10 || [self.tmpPassword length] > 255) {
        [app standardNotify:BC_STRING_PASSWORD_MUST_10_CHARACTERS_OR_LONGER];
        [passwordTextField becomeFirstResponder];
        return NO;
    }
    
    if (![self.tmpPassword isEqualToString:[password2TextField text]]) {
        [app standardNotify:BC_STRING_PASSWORDS_DO_NOT_MATCH];
        [password2TextField becomeFirstResponder];
        return NO;
    }
        
    if (![app checkInternetConnection]) {
        return NO;
    }
    
    return YES;
}

- (void)closeKeyboard
{
    [emailTextField resignFirstResponder];
    [passwordTextField resignFirstResponder];
    [password2TextField resignFirstResponder];
}

#pragma mark - Wallet Delegate method

- (void)walletJSReady
{
    // JS is loaded - now create the wallet
    [app.wallet newAccount:self.tmpPassword email:emailTextField.text];
}

- (IBAction)termsOfServiceClicked:(id)sender
{
    [app pushWebViewController:[WebROOT stringByAppendingString:@"terms_of_service"] title:BC_STRING_TERMS_OF_SERVICE];
    [emailTextField becomeFirstResponder];
}

- (void)didCreateNewAccount:(NSString*)guid sharedKey:(NSString*)sharedKey password:(NSString*)password
{
    emailTextField.text = nil;
    passwordTextField.text = nil;
    password2TextField.text = nil;
    
    // TODO Whitelist the new account - this needs to be removed again when we remove the beta invite system XXX
    [app.wallet whitelistWallet];
    
    // TODO XXX  dispatch is only here because of the whitelist call above, remove when that is removed
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Reset wallet
        [app forgetWallet];
        
        // Load the newly created wallet
        [app.wallet loadWalletWithGuid:guid sharedKey:sharedKey password:password];
        
        app.wallet.delegate = app;
        
        [app standardNotify:[NSString stringWithFormat:BC_STRING_DID_CREATE_NEW_ACCOUNT_DETAIL]
                      title:BC_STRING_DID_CREATE_NEW_ACCOUNT_TITLE
                   delegate:nil];
    });
}

- (void)errorCreatingNewAccount:(NSString*)message
{
    if ([message isEqualToString:@""]) {
        [app standardNotify:BC_STRING_NO_INTERNET_CONNECTION title:BC_STRING_ERROR delegate:nil];
    } else {
        [app standardNotify:message];
    }
}

#pragma mark - Textfield Delegates

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == passwordTextField) {
        [self performSelector:@selector(checkPasswordStrength) withObject:nil afterDelay:0.01];
    }
    
    return YES;
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    if (passwordTextField.text.length == 0) {
        passwordFeedbackLabel.hidden = YES;
        passwordStrengthMeter.hidden = YES;
    }
}

- (void)checkPasswordStrength
{
    passwordFeedbackLabel.hidden = NO;
    passwordStrengthMeter.hidden = NO;
    
    NSString *password = passwordTextField.text;
    
    UIColor *color;
    NSString *description;
    
    CGFloat passwordStrength = [app.wallet getStrengthForPassword:password];

    if (passwordStrength < 25) {
        color = COLOR_PASSWORD_STRENGTH_WEAK;
        description = BC_STRING_PASSWORD_STRENGTH_WEAK;
    }
    else if (passwordStrength < 50) {
        color = COLOR_PASSWORD_STRENGTH_REGULAR;
        description = BC_STRING_PASSWORD_STRENGTH_REGULAR;
    }
    else if (passwordStrength < 75) {
        color = COLOR_PASSWORD_STRENGTH_NORMAL;
        description = BC_STRING_PASSWORD_STRENGTH_NORMAL;
    }
    else {
        color = COLOR_PASSWORD_STRENGTH_STRONG;
        description = BC_STRING_PASSWORD_STRENGTH_STRONG;
    }
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        passwordFeedbackLabel.text = description;
        passwordFeedbackLabel.textColor = color;
        passwordStrengthMeter.progress = passwordStrength/100;
        passwordStrengthMeter.progressTintColor = color;
        passwordTextField.layer.borderColor = color.CGColor;
    }];
}

@end

//
//  BCContactRequestView.m
//  Blockchain
//
//  Created by kevinwu on 1/9/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCContactRequestView.h"
#import "RootService.h"
#import "BCLine.h"
#import "Blockchain-Swift.h"

@interface BCContactRequestView ()
@property (nonatomic) NSString *reason;
@property (nonatomic) UIButton *nextButton;

@property (nonatomic) UILabel *receiveBtcLabel;
@property (nonatomic) UILabel *receiveFiatLabel;

@property (nonatomic) UITextField *receiveBtcField;
@property (nonatomic) UITextField *receiveFiatField;
@end

@implementation BCContactRequestView

- (id)initWithContactName:(NSString *)name reason:(NSString *)reason willSend:(BOOL)willSend
{
    UIWindow *window = app.window;
    
    self = [super initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, window.frame.size.width, window.frame.size.height - DEFAULT_HEADER_HEIGHT)];
    
    if (self) {
        _willSend = willSend;
        self.reason = reason;
        
        self.backgroundColor = [UIColor whiteColor];

        UILabel *promptLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 55, window.frame.size.width - 40, 80)];
        promptLabel.textColor = [UIColor darkGrayColor];
        promptLabel.font = [UIFont systemFontOfSize:17.0];
        promptLabel.numberOfLines = 0;
        [self addSubview:promptLabel];
        
        
        // Input accessory view
        
        self.nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
        self.nextButton.frame = CGRectMake(0, 0, window.frame.size.width, 46);
        self.nextButton.backgroundColor = COLOR_BUTTON_BLUE;
        [self.nextButton setTitle:BC_STRING_NEXT forState:UIControlStateNormal];
        [self.nextButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
        self.nextButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
        
        if (reason) {
            promptLabel.text = [NSString stringWithFormat:[self getPromptTextForAmount], name];
            [self.nextButton addTarget:self action:@selector(notifyContact) forControlEvents:UIControlEventTouchUpInside];
            
            UIView *bottomContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, promptLabel.frame.origin.y + promptLabel.frame.size.height + 8, self.frame.size.width, 100)];
            [self addSubview:bottomContainerView];
            
            BCLine *lineAboveAmounts = [[BCLine alloc] initWithFrame:CGRectMake(15, 0, self.frame.size.width - 15, 1)];
            BCLine *lineBelowAmounts = [[BCLine alloc] initWithFrame:CGRectMake(15, 50, self.frame.size.width - 15, 1)];
            lineAboveAmounts.backgroundColor = COLOR_LINE_GRAY;
            lineBelowAmounts.backgroundColor = COLOR_LINE_GRAY;
            [bottomContainerView addSubview:lineAboveAmounts];
            [bottomContainerView addSubview:lineBelowAmounts];
            
            self.receiveBtcLabel = [[UILabel alloc] initWithFrame:CGRectMake(lineAboveAmounts.frame.origin.x, 15, 40, 21)];
            self.receiveBtcLabel.font = [UIFont systemFontOfSize:13];
            self.receiveBtcLabel.textColor = [UIColor lightGrayColor];
            self.receiveBtcLabel.text = app.latestResponse.symbol_btc.symbol;
            [bottomContainerView addSubview:self.receiveBtcLabel];
            
            self.receiveBtcField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(self.receiveBtcLabel.frame.origin.x + 53, 10, 117, 30)];
            self.receiveBtcField.font = [UIFont systemFontOfSize:13];
            self.receiveBtcField.placeholder = [NSString stringWithFormat:BTC_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
            self.receiveBtcField.keyboardType = UIKeyboardTypeDecimalPad;
            self.receiveBtcField.inputAccessoryView = self.nextButton;
            self.receiveBtcField.delegate = self;
            [bottomContainerView addSubview:self.receiveBtcField];
            
            self.receiveFiatLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.frame.size.width - 136, 15, 40, 21)];
            self.receiveFiatLabel.font = [UIFont systemFontOfSize:13];
            self.receiveFiatLabel.textColor = [UIColor lightGrayColor];
            self.receiveFiatLabel.text = app.latestResponse.symbol_local.code;
            [bottomContainerView addSubview:self.receiveFiatLabel];
            
            self.receiveFiatField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(self.receiveFiatLabel.frame.origin.x + 47, 10, 117, 30)];
            self.receiveFiatField.font = [UIFont systemFontOfSize:13];
            self.receiveFiatField.placeholder = [NSString stringWithFormat:FIAT_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
            self.receiveFiatField.keyboardType = UIKeyboardTypeDecimalPad;
            self.receiveFiatField.inputAccessoryView = _nextButton;
            self.receiveFiatField.delegate = self;
            [bottomContainerView addSubview:self.receiveFiatField];
            
        } else {
            promptLabel.text = [NSString stringWithFormat:[self getPromptTextForReason], name, name];
            [self.nextButton addTarget:self action:@selector(promptAmount) forControlEvents:UIControlEventTouchUpInside];
            
            
            _textField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(20, 145, window.frame.size.width - 40, 30)];
            _textField.borderStyle = UITextBorderStyleRoundedRect;
            _textField.autocapitalizationType = UITextAutocapitalizationTypeSentences;
            _textField.autocorrectionType = UITextAutocorrectionTypeNo;
            _textField.spellCheckingType = UITextSpellCheckingTypeNo;
            [self addSubview:_textField];
            
            [_textField setReturnKeyType:UIReturnKeyNext];
            _textField.delegate = self;
            _textField.inputAccessoryView = self.nextButton;
        }
    }
    return self;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField
{
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.receiveBtcField || textField == self.receiveFiatField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray  *points = [newString componentsSeparatedByString:@"."];
        NSLocale *locale = [textField.textInputMode.primaryLanguage isEqualToString:LOCALE_IDENTIFIER_AR] ? [NSLocale localeWithLocaleIdentifier:textField.textInputMode.primaryLanguage] : [NSLocale currentLocale];
        NSArray  *commas = [newString componentsSeparatedByString:[locale objectForKey:NSLocaleDecimalSeparator]];
        
        // Only one comma or point in input field allowed
        if ([points count] > 2 || [commas count] > 2)
            return NO;
        
        // Only 1 leading zero
        if (points.count == 1 || commas.count == 1) {
            if (range.location == 1 && ![string isEqualToString:@"."] && ![string isEqualToString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]] && [textField.text isEqualToString:@"0"]) {
                return NO;
            }
        }
        
        // When entering amount in BTC, max 8 decimal places
        if ([self.receiveBtcField isFirstResponder]) {
            // Max number of decimal places depends on bitcoin unit
            NSUInteger maxlength = [@(SATOSHI) stringValue].length - [@(SATOSHI / app.latestResponse.symbol_btc.conversion) stringValue].length;
            
            if (points.count == 2) {
                NSString *decimalString = points[1];
                if (decimalString.length > maxlength) {
                    return NO;
                }
            }
            else if (commas.count == 2) {
                NSString *decimalString = commas[1];
                if (decimalString.length > maxlength) {
                    return NO;
                }
            }
        }
        
        // Fiat currencies have a max of 3 decimal places, most of them actually only 2. For now we will use 2.
        else if ([self.receiveFiatField isFirstResponder]) {
            if (points.count == 2) {
                NSString *decimalString = points[1];
                if (decimalString.length > 2) {
                    return NO;
                }
            }
            else if (commas.count == 2) {
                NSString *decimalString = commas[1];
                if (decimalString.length > 2) {
                    return NO;
                }
            }
        }
        
        uint64_t amountInSatoshi = 0;
        
        if (textField == self.receiveFiatField) {
            NSString *amountString = [newString stringByReplacingOccurrencesOfString:[locale objectForKey:NSLocaleDecimalSeparator] withString:@"."];
            amountInSatoshi = app.latestResponse.symbol_local.conversion * [amountString doubleValue];
        }
        else {
            amountInSatoshi = [app.wallet parseBitcoinValueFromString:newString locale:locale];
        }
        
        if (amountInSatoshi > BTC_LIMIT_IN_SATOSHI) {
            return NO;
        } else {
            [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
            return YES;
        }
    } else {
        return YES;
    }
}

- (BOOL)shouldUseBtcField
{
    BOOL shouldUseBtcField = YES;
    
    if ([self.receiveBtcField isFirstResponder]) {
        shouldUseBtcField = YES;
    } else if ([self.receiveFiatField isFirstResponder]) {
        shouldUseBtcField = NO;
    }

    return shouldUseBtcField;
}

- (uint64_t)getInputAmountInSatoshi
{
    if ([self shouldUseBtcField]) {
        return [app.wallet parseBitcoinValueFromTextField:self.receiveBtcField];
    } else {
        NSString *language = self.receiveFiatField.textInputMode.primaryLanguage;
        NSLocale *locale = [language isEqualToString:LOCALE_IDENTIFIER_AR] ? [NSLocale localeWithLocaleIdentifier:language] : [NSLocale currentLocale];
        NSString *requestedAmountString = [self.receiveFiatField.text stringByReplacingOccurrencesOfString:[locale objectForKey:NSLocaleDecimalSeparator] withString:@"."];
        return app.latestResponse.symbol_local.conversion * [requestedAmountString doubleValue];
    }
    
    return 0;
}

- (void)doCurrencyConversion
{
    uint64_t amount = [self getInputAmountInSatoshi];
    
    if ([self shouldUseBtcField]) {
        self.receiveFiatField.text = [NSNumberFormatter formatAmount:amount localCurrency:YES];
    } else {
        self.receiveBtcField.text = [NSNumberFormatter formatAmount:amount localCurrency:NO];
    }
}

- (void)showKeyboard
{
    if (self.textField) {
        [self.textField becomeFirstResponder];
    } else {
        if (app->symbolLocal) {
            [self.receiveFiatField becomeFirstResponder];
        } else {
            [self.receiveBtcField becomeFirstResponder];
        }
    }
}

- (NSString *)getPromptTextForReason
{
    return self.willSend ? BC_STRING_PROMPT_REASON_SEND_ARGUMENT_ARGUMENT : BC_STRING_PROMPT_REASON_RECEIVE_ARGUMENT_ARGUMENT;
}

- (NSString *)getPromptTextForAmount
{
    return self.willSend ? BC_STRING_PROMPT_AMOUNT_SEND_ARGUMENT : BC_STRING_PROMPT_AMOUNT_RECEIVE_ARGUMENT;
}

- (void)promptAmount
{
    if (self.willSend) {
        [self.delegate promptSendAmount:self.textField.text];
    } else {
        [self.delegate promptRequestAmount:self.textField.text];
    }
}

- (void)notifyContact
{
    NSLocale *locale = [self.receiveBtcField.textInputMode.primaryLanguage isEqualToString:LOCALE_IDENTIFIER_AR] ? [NSLocale localeWithLocaleIdentifier:self.receiveBtcField.textInputMode.primaryLanguage] : [NSLocale currentLocale];
    
    if (self.willSend) {
        [self.delegate createSendRequestWithReason:self.reason amount:[app.wallet parseBitcoinValueFromString:self.receiveBtcField.text locale:locale]];
    } else {
        [self.delegate createReceiveRequestWithReason:self.reason amount:[app.wallet parseBitcoinValueFromString:self.receiveBtcField.text locale:locale]];
    }
}

@end

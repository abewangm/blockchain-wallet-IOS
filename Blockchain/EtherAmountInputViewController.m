//
//  EtherAmountInputViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/28/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "EtherAmountInputViewController.h"
#import "BCAmountInputView.h"
#import "NSNumberFormatter+Currencies.h"

@interface EtherAmountInputViewController ()
@property (nonatomic) NSDecimalNumber *latestExchangeRate;
@property (nonatomic) UITextField *toField;
@property (nonatomic) BCAmountInputView *amountInputView;
@property (nonatomic) NSString *toAddress;
@property (nonatomic) NSDecimalNumber *ethAmount;
@end

@implementation EtherAmountInputViewController

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == self.amountInputView.btcField || textField == self.amountInputView.fiatField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray  *points = [newString componentsSeparatedByString:@"."];
        NSLocale *locale = [textField.textInputMode.primaryLanguage isEqualToString:LOCALE_IDENTIFIER_AR] ? [NSLocale localeWithLocaleIdentifier:textField.textInputMode.primaryLanguage] : [NSLocale currentLocale];
        NSArray  *commas = [newString componentsSeparatedByString:[locale objectForKey:NSLocaleDecimalSeparator]];
        
        // Only one comma or point in input field allowed
        if ([points count] > 2 || [commas count] > 2)
            return NO;
        
        // Only 1 leading zero
        if (points.count == 1 || commas.count == 1) {
            if (range.location == 1 && ![string isEqualToString:@"."] && ![string isEqualToString:@","] && ![string isEqualToString:@"٫"] && [textField.text isEqualToString:@"0"]) {
                return NO;
            }
        }
        
        // When entering amount in ETH, max 18 decimal places
        if (textField == self.amountInputView.btcField) {
            // Max number of decimal places depends on bitcoin unit
            NSUInteger maxlength = ETH_DECIMAL_LIMIT;
            
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
        else if (textField == self.amountInputView.fiatField) {
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
        
        if (textField == self.amountInputView.fiatField) {
            // Convert input amount to internal value
            NSString *amountString = [newString stringByReplacingOccurrencesOfString:@"," withString:@"."];
            if (![amountString containsString:@"."]) {
                amountString = [newString stringByReplacingOccurrencesOfString:@"٫" withString:@"."];
            }
            
            NSDecimalNumber *amountStringDecimalNumber = amountString && [amountString doubleValue] > 0 ? [NSDecimalNumber decimalNumberWithString:amountString] : 0;
            self.ethAmount = [NSNumberFormatter convertFiatToEth:amountStringDecimalNumber exchangeRate:self.latestExchangeRate];
        }
        else if (textField == self.amountInputView.btcField) {
            self.ethAmount = [NSDecimalNumber decimalNumberWithString:newString];
        }
        

        [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
        return YES;
    } else if (textField == self.toField) {
        self.toAddress = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (self.toAddress && [self isEtherAddress:self.toAddress]) {
            [self selectToAddress:self.toAddress];
            return NO;
        }
        
        DLog(@"toAddress: %@", self.toAddress);
    }
    
    return YES;
}

- (void)selectToAddress:(NSString *)address
{
    DLog(@"EtherInputAmountViewController warning - selectToAddress was called but was not overridden!");
}

- (void)doCurrencyConversion
{
    if ([self.amountInputView.btcField isFirstResponder]) {
        self.amountInputView.fiatField.text = [NSNumberFormatter formatEthToFiat:self.amountInputView.btcField.text exchangeRate:self.latestExchangeRate];
    } else if ([self.amountInputView.fiatField isFirstResponder]){
        self.amountInputView.btcField.text = [NSNumberFormatter formatFiatToEth:self.amountInputView.fiatField.text exchangeRate:self.latestExchangeRate];
    }
}

- (BOOL)isEtherAddress:(NSString *)address
{
    DLog(@"EtherInputAmountViewController warning: isEtherAddress has not yet been implemented");
    return YES;
}

@end

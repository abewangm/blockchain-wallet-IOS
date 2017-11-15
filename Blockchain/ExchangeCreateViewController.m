//
//  ExchangeCreateViewController.m
//  Blockchain
//
//  Created by kevinwu on 10/23/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeCreateViewController.h"
#import "FromToView.h"
#import "Blockchain-Swift.h"

#define COLOR_EXCHANGE_BACKGROUND_GRAY UIColorFromRGB(0xf5f6f8)

@interface ExchangeCreateViewController () <UITextFieldDelegate>

@property (nonatomic) BCSecureTextField *bottomLeftField;
@property (nonatomic) BCSecureTextField *bottomRightField;

@property (nonatomic) BCSecureTextField *topLeftField;
@property (nonatomic) BCSecureTextField *topRightField;
@property (nonatomic) BCSecureTextField *btcField;
@property (nonatomic) BCSecureTextField *ethField;

@property (nonatomic) uint64_t btcAmount;
@property (nonatomic) NSDecimalNumber *ethAmount;
@end

@implementation ExchangeCreateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = COLOR_EXCHANGE_BACKGROUND_GRAY;
    
    CGFloat windowWidth = WINDOW_WIDTH;
    FromToView *fromToView = [[FromToView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT + 16, windowWidth, 96) enableToTextField:NO];
    [self.view addSubview:fromToView];
    
    UIView *amountView = [[UIView alloc] initWithFrame:CGRectMake(0, fromToView.frame.origin.y + fromToView.frame.size.height + 1, windowWidth, 100)];
    amountView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:amountView];
    
    UILabel *leftTopLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 40, 30)];
    leftTopLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    leftTopLabel.textColor = COLOR_TEXT_DARK_GRAY;
    leftTopLabel.text = CURRENCY_SYMBOL_BTC;
    [amountView addSubview:leftTopLabel];
    
    UIButton *assetToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 12, 30, 30)];
    assetToggleButton.center = CGPointMake(windowWidth/2, assetToggleButton.center.y);
    [amountView addSubview:assetToggleButton];
    
    UILabel *rightTopLabel = [[UILabel alloc] initWithFrame:CGRectMake(assetToggleButton.frame.origin.x + assetToggleButton.frame.size.width + 15, 12, 40, 30)];
    rightTopLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    rightTopLabel.textColor = COLOR_TEXT_DARK_GRAY;
    rightTopLabel.text = CURRENCY_SYMBOL_ETH;
    [amountView addSubview:rightTopLabel];
    
    CGFloat leftFieldOriginX = leftTopLabel.frame.origin.x + leftTopLabel.frame.size.width + 8;
    BCSecureTextField *leftField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(leftFieldOriginX, 12, assetToggleButton.frame.origin.x - 8 - leftFieldOriginX, 30)];
    leftField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    leftField.textColor = COLOR_TEXT_DARK_GRAY;
    [amountView addSubview:leftField];
    leftField.delegate = self;
    self.topLeftField = leftField;
    self.btcField = self.topLeftField;
    
    CGFloat rightFieldOriginX = rightTopLabel.frame.origin.x + rightTopLabel.frame.size.width + 8;
    BCSecureTextField *rightField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(rightFieldOriginX, 12, windowWidth - 8 - rightFieldOriginX, 30)];
    rightField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    rightField.textColor = COLOR_TEXT_DARK_GRAY;
    [amountView addSubview:rightField];
    rightField.delegate = self;
    self.topRightField = rightField;
    self.ethField = self.topRightField;
    
    UIView *dividerLine = [[UIView alloc] initWithFrame:CGRectMake(leftFieldOriginX, leftField.frame.origin.y + leftField.frame.size.height + 12, windowWidth - leftFieldOriginX, 0.5)];
    dividerLine.backgroundColor = COLOR_LINE_GRAY;
    [amountView addSubview:dividerLine];
    
    BCSecureTextField *bottomLeftField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(leftFieldOriginX, dividerLine.frame.origin.y + dividerLine.frame.size.height + 12, leftField.frame.size.width, 30)];
    bottomLeftField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    bottomLeftField.textColor = COLOR_TEXT_DARK_GRAY;
    [amountView addSubview:bottomLeftField];
    self.bottomLeftField = bottomLeftField;
    
    BCSecureTextField *bottomRightField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(rightFieldOriginX, dividerLine.frame.origin.y + dividerLine.frame.size.height + 12, rightField.frame.size.width, 30)];
    bottomRightField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    bottomRightField.textColor = COLOR_TEXT_DARK_GRAY;
    [amountView addSubview:bottomRightField];
    self.bottomRightField = bottomRightField;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
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
    if (textField == self.ethField) {
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
    
    // When entering amount in BTC, max 8 decimal places
    else if (textField == self.btcField) {
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
    else if (textField == self.bottomLeftField || self.bottomRightField) {
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
    
    NSString *amountString = [newString stringByReplacingOccurrencesOfString:@"," withString:@"."];
    if (![amountString containsString:@"."]) {
        amountString = [newString stringByReplacingOccurrencesOfString:@"٫" withString:@"."];
    }
    
    [self saveAmount:amountString fromField:textField];
    
    [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
    return YES;
}

- (void)saveAmount:(NSString *)amountString fromField:(UITextField *)textField
{
    if (textField == self.ethField) {
        self.ethAmount = [NSDecimalNumber decimalNumberWithString:amountString];
    } else if (textField == self.btcField) {
        self.btcAmount = [app.wallet parseBitcoinValueFromString:amountString];
    } else {
        if (textField == self.bottomLeftField) {
            if (self.topLeftField == self.ethField) {
                [self convertFiatStringToEth:amountString];
            } else if (self.topLeftField == self.btcField) {
                [self convertFiatStringToBtc:amountString];
            }
        } else if (textField == self.bottomRightField) {
            if (self.topRightField == self.ethField) {
                [self convertFiatStringToEth:amountString];
            } else if (self.topRightField == self.btcField) {
                [self convertFiatStringToBtc:amountString];
            }
        }
    }
}

- (void)convertFiatStringToEth:(NSString *)amountString
{
    NSDecimalNumber *amountStringDecimalNumber = amountString && [amountString doubleValue] > 0 ? [NSDecimalNumber decimalNumberWithString:amountString] : 0;
    self.ethAmount = [NSNumberFormatter convertFiatToEth:amountStringDecimalNumber exchangeRate:app.wallet.latestEthExchangeRate];
}

- (void)convertFiatStringToBtc:(NSString *)amountString
{
    self.btcAmount = app.latestResponse.symbol_local.conversion * [amountString doubleValue];
}

- (void)doCurrencyConversion
{
    if ([self.btcField isFirstResponder]) {
        
    } else if ([self.ethField isFirstResponder]) {
        
    }
}

@end

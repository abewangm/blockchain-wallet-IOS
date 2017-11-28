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
#import "ContinueButtonInputAccessoryView.h"
#import "ExchangeTrade.h"

#define COLOR_EXCHANGE_BACKGROUND_GRAY UIColorFromRGB(0xf5f6f8)

#define DICTIONARY_KEY_TRADE_MINIMUM @"minimum"
#define DICTIONARY_KEY_TRADE_MAX_LIMIT @"maxLimit"

#define IMAGE_NAME_SWITCH_CURRENCIES @"switch_currencies"

@interface ExchangeCreateViewController () <UITextFieldDelegate, FromToButtonDelegate, AddressSelectionDelegate, ContinueButtonInputAccessoryViewDelegate>

@property (nonatomic) FromToView *fromToView;

@property (nonatomic) UILabel *leftLabel;
@property (nonatomic) UILabel *rightLabel;

@property (nonatomic) UIButton *assetToggleButton;

// Digital asset input
@property (nonatomic) BCSecureTextField *topLeftField;
@property (nonatomic) BCSecureTextField *topRightField;
@property (nonatomic) BCSecureTextField *btcField;
@property (nonatomic) BCSecureTextField *ethField;

// Fiat input
@property (nonatomic) BCSecureTextField *bottomLeftField;
@property (nonatomic) BCSecureTextField *bottomRightField;

@property (nonatomic) UITextView *errorTextView;

@property (nonatomic) id amount;
@property (nonatomic) int btcAccount;

@property (nonatomic) NSString *fromSymbol;
@property (nonatomic) NSString *toSymbol;
@property (nonatomic) NSString *fromAddress;
@property (nonatomic) NSString *toAddress;

@property (nonatomic) NSURLSessionDataTask *currentDataTask;

// uint64_t or NSDecimalNumber
@property (nonatomic) id minimum;
@property (nonatomic) id maximum;
@property (nonatomic) id availableBalance;
@property (nonatomic) id fee;

@property (nonatomic) UIActivityIndicatorView *spinner;

@property (nonatomic) ContinueButtonInputAccessoryView *continuePaymentAccessoryView;
@end

@implementation ExchangeCreateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setupViews];
    
    self.fromSymbol = CURRENCY_SYMBOL_BTC;
    self.toSymbol = CURRENCY_SYMBOL_ETH;
    self.btcAccount = [app.wallet getDefaultAccountIndex];
    
    self.amount = 0;
    
    [self getRate:[NSString stringWithFormat:@"%@_%@", self.fromSymbol, self.toSymbol]];
}

- (void)setupViews
{
    self.view.backgroundColor = COLOR_EXCHANGE_BACKGROUND_GRAY;
    
    CGFloat windowWidth = WINDOW_WIDTH;
    FromToView *fromToView = [[FromToView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT + 16, windowWidth, 96) enableToTextField:NO];
    fromToView.delegate = self;
    [self.view addSubview:fromToView];
    self.fromToView = fromToView;
    
    UIView *amountView = [[UIView alloc] initWithFrame:CGRectMake(0, fromToView.frame.origin.y + fromToView.frame.size.height + 1, windowWidth, 100)];
    amountView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:amountView];
    
    UILabel *topLeftLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 40, 30)];
    topLeftLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    topLeftLabel.textColor = COLOR_TEXT_DARK_GRAY;
    topLeftLabel.text = CURRENCY_SYMBOL_BTC;
    self.leftLabel = topLeftLabel;
    [amountView addSubview:topLeftLabel];
    
    UIButton *assetToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 12, 30, 30)];
    assetToggleButton.center = CGPointMake(windowWidth/2, assetToggleButton.center.y);
    [assetToggleButton addTarget:self action:@selector(assetToggleButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    UIImage *buttonImage = [UIImage imageNamed:IMAGE_NAME_SWITCH_CURRENCIES];
    [assetToggleButton setImage:buttonImage forState:UIControlStateNormal];
    assetToggleButton.imageView.transform = CGAffineTransformMakeRotation(M_PI/2);
    [amountView addSubview:assetToggleButton];
    self.assetToggleButton = assetToggleButton;
    
    self.spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    self.spinner.center = assetToggleButton.center;
    [amountView addSubview:self.spinner];
    self.spinner.hidden = YES;
    
    UILabel *topRightLabel = [[UILabel alloc] initWithFrame:CGRectMake(assetToggleButton.frame.origin.x + assetToggleButton.frame.size.width + 15, 12, 40, 30)];
    topRightLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    topRightLabel.textColor = COLOR_TEXT_DARK_GRAY;
    topRightLabel.text = CURRENCY_SYMBOL_ETH;
    self.rightLabel = topRightLabel;
    [amountView addSubview:topRightLabel];
    
    ContinueButtonInputAccessoryView *inputAccessoryView = [[ContinueButtonInputAccessoryView alloc] init];
    inputAccessoryView.delegate = self;
    self.continuePaymentAccessoryView = inputAccessoryView;
    
    CGFloat leftFieldOriginX = topLeftLabel.frame.origin.x + topLeftLabel.frame.size.width + 8;
    BCSecureTextField *leftField = [self inputTextFieldWithFrame:CGRectMake(leftFieldOriginX, 12, assetToggleButton.frame.origin.x - 8 - leftFieldOriginX, 30)];
    [amountView addSubview:leftField];
    leftField.inputAccessoryView = inputAccessoryView;
    self.topLeftField = leftField;
    self.btcField = self.topLeftField;
    
    CGFloat rightFieldOriginX = topRightLabel.frame.origin.x + topRightLabel.frame.size.width + 8;
    BCSecureTextField *rightField = [self inputTextFieldWithFrame:CGRectMake(rightFieldOriginX, 12, windowWidth - 8 - rightFieldOriginX, 30)];
    [amountView addSubview:rightField];
    rightField.inputAccessoryView = inputAccessoryView;
    self.topRightField = rightField;
    self.ethField = self.topRightField;
    
    UIView *dividerLine = [[UIView alloc] initWithFrame:CGRectMake(leftFieldOriginX, leftField.frame.origin.y + leftField.frame.size.height + 12, windowWidth - leftFieldOriginX, 0.5)];
    dividerLine.backgroundColor = COLOR_LINE_GRAY;
    [amountView addSubview:dividerLine];
    
    BCSecureTextField *bottomLeftField = [self inputTextFieldWithFrame:CGRectMake(leftFieldOriginX, dividerLine.frame.origin.y + dividerLine.frame.size.height + 12, leftField.frame.size.width, 30)];
    [amountView addSubview:bottomLeftField];
    bottomLeftField.inputAccessoryView = inputAccessoryView;
    self.bottomLeftField = bottomLeftField;
    
    BCSecureTextField *bottomRightField = [self inputTextFieldWithFrame:CGRectMake(rightFieldOriginX, dividerLine.frame.origin.y + dividerLine.frame.size.height + 12, rightField.frame.size.width, 30)];
    [amountView addSubview:bottomRightField];
    bottomRightField.inputAccessoryView = inputAccessoryView;
    self.bottomRightField = bottomRightField;
    
    self.fromToView.fromImageView.image = [UIImage imageNamed:@"chevron_right"];
    self.fromToView.toImageView.image = [UIImage imageNamed:@"chevron_right"];
    
    CGFloat buttonHeight = 50;
    BCLine *lineAboveButtonsView = [[BCLine alloc] initWithYPosition:amountView.frame.origin.y + amountView.frame.size.height];
    [self.view addSubview:lineAboveButtonsView];
    UIView *buttonsView = [[UIView alloc] initWithFrame:CGRectMake(0, amountView.frame.origin.y + amountView.frame.size.height + 0.5, windowWidth, buttonHeight)];
    buttonsView.backgroundColor = COLOR_LINE_GRAY;
    [self.view addSubview:buttonsView];
    
    UIFont *buttonFont = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    CGFloat dividerLineWidth = 0.5;
    UIButton *useMinButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, buttonsView.frame.size.width/2 - dividerLineWidth/2, buttonHeight)];
    useMinButton.titleLabel.font = buttonFont;
    useMinButton.backgroundColor = [UIColor whiteColor];
    [useMinButton setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateNormal];
    [useMinButton setTitle:BC_STRING_USE_MINIMUM forState:UIControlStateNormal];
    [useMinButton addTarget:self action:@selector(useMinButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [buttonsView addSubview:useMinButton];
    
    CGFloat useMaxButtonOriginX = buttonsView.frame.size.width/2 + dividerLineWidth/2;
    UIButton *useMaxButton = [[UIButton alloc] initWithFrame:CGRectMake(useMaxButtonOriginX, 0, buttonsView.frame.size.width - useMaxButtonOriginX, buttonHeight)];
    useMaxButton.titleLabel.font = buttonFont;
    useMaxButton.backgroundColor = [UIColor whiteColor];
    [useMaxButton setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateNormal];
    [useMaxButton setTitle:BC_STRING_USE_MAXIMUM forState:UIControlStateNormal];
    [useMaxButton addTarget:self action:@selector(useMaxButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [buttonsView addSubview:useMaxButton];
    
    UITextView *errorTextView = [[UITextView alloc] initWithFrame:CGRectMake(15, buttonsView.frame.origin.y + buttonsView.frame.size.height + 8, windowWidth - 30, 30)];
    errorTextView.editable = NO;
    errorTextView.scrollEnabled = NO;
    errorTextView.selectable = NO;
    errorTextView.textColor = COLOR_WARNING_RED;
    errorTextView.font = buttonFont;
    errorTextView.backgroundColor = [UIColor clearColor];
    [self.view addSubview:errorTextView];
    errorTextView.hidden = YES;
    self.errorTextView = errorTextView;
}

#pragma mark - JS Callbacks

- (void)didGetExchangeRate:(NSDictionary *)result
{
    [self enableAssetToggleButton];
    [self.spinner stopAnimating];
    
    if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_BTC]) {
        NSString *minNumberString = [result objectForKey:DICTIONARY_KEY_TRADE_MINIMUM];
        self.minimum = [NSNumber numberWithLongLong:[app.wallet parseBitcoinValueFromString:minNumberString]];
        NSString *maxNumberString = [result objectForKey:DICTIONARY_KEY_TRADE_MAX_LIMIT];
        self.maximum = [NSNumber numberWithLongLong:[app.wallet parseBitcoinValueFromString:maxNumberString]];
        [app.wallet getAvailableBtcBalanceForAccount:self.btcAccount];
    } else if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_ETH]) {
        self.minimum = [NSDecimalNumber decimalNumberWithString:[result objectForKey:DICTIONARY_KEY_TRADE_MINIMUM]];
        self.maximum = [NSDecimalNumber decimalNumberWithString:[result objectForKey:DICTIONARY_KEY_TRADE_MAX_LIMIT]];
        [app.wallet getAvailableEthBalance];
    }
}

- (void)didGetAvailableEthBalance:(NSDictionary *)result
{
    self.availableBalance = [result objectForKey:DICTIONARY_KEY_AMOUNT];
    self.fee = [result objectForKey:DICTIONARY_KEY_FEE];
    
    [self updateAvailableBalance];
}

- (void)didGetAvailableBtcBalance:(NSDictionary *)result
{
    self.availableBalance = [result objectForKey:DICTIONARY_KEY_AMOUNT];
    self.fee = [result objectForKey:DICTIONARY_KEY_FEE];
    
    [self updateAvailableBalance];
}

- (void)updateAvailableBalance
{
    BOOL overAvailable = NO;
    BOOL overMax = NO;
    BOOL underMin = NO;
    BOOL zeroAmount = NO;
    
    self.errorTextView.text = @"test";
    
    if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_BTC]) {
        
        uint64_t amount = [self.amount longLongValue];
        
        DLog(@"btc amount: %lld", amount);
        DLog(@"available: %lld", [self.availableBalance longLongValue]);
        DLog(@"max: %lld", [self.maximum longLongValue])
        
        if (amount == 0) zeroAmount = YES;
        
        if (amount > [self.availableBalance longLongValue]) {
            DLog(@"btc over available");
            overAvailable = YES;
        }
        
        if (amount > [self.maximum longLongValue]) {
            DLog(@"btc over max");
            overMax = YES;
        }
        
        if (amount < [self.minimum longLongValue] ) {
            DLog(@"btc under min");
            underMin = YES;
        }
        
    } else if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_ETH]) {
        DLog(@"eth amount: %@", [self.amount stringValue]);
        DLog(@"available: %@", [self.availableBalance stringValue]);
        DLog(@"max: %@", [self.maximum stringValue])
        
        if ([self.amount compare:@0] == NSOrderedSame || !self.amount) {
            zeroAmount = YES;
        }
        
        if ([self.amount compare:self.availableBalance] == NSOrderedDescending) {
            DLog(@"eth over available");
            overAvailable = YES;
        }
        
        if ([self.amount compare:self.maximum] == NSOrderedDescending) {
            DLog(@"eth over max");
            overMax = YES;
        }
        
        if ([self.amount compare:self.minimum] == NSOrderedAscending) {
            DLog(@"eth under min");
            underMin = YES;
        }
    }
    
    if (zeroAmount) {
        self.errorTextView.hidden = YES;
    } else if (overAvailable || overMax || underMin) {
        self.errorTextView.hidden = NO;
    } else {
        self.errorTextView.hidden = YES;
    }
}

- (void)enablePaymentButtons
{
    [self.continuePaymentAccessoryView enableContinueButton];
}

- (void)disablePaymentButtons
{
    [self.continuePaymentAccessoryView disableContinueButton];

}

- (void)didGetQuote:(NSDictionary *)result
{
    
}

- (void)didGetApproximateQuote:(NSDictionary *)result
{
    [self enablePaymentButtons];
    [self enableAssetToggleButton];
    [self.spinner stopAnimating];
}

- (void)didBuildExchangeTrade:(NSDictionary *)tradeInfo payment:(id)payment
{
    ExchangeTrade *trade = [ExchangeTrade fromJSONDict:tradeInfo];
    
}

#pragma mark - Conversion

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
        self.amount = [NSDecimalNumber decimalNumberWithString:amountString];
    } else if (textField == self.btcField) {
        self.amount = [NSNumber numberWithLongLong:[app.wallet parseBitcoinValueFromString:amountString]];
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
    self.amount = [NSNumberFormatter convertFiatToEth:amountStringDecimalNumber exchangeRate:app.wallet.latestEthExchangeRate];
}

- (void)convertFiatStringToBtc:(NSString *)amountString
{
    self.amount = [NSNumber numberWithLongLong:app.latestResponse.symbol_local.conversion * [amountString doubleValue]];
}

- (NSString *)convertBtcAmountToFiat
{
    return [NSNumberFormatter formatAmount:[self.amount longLongValue] localCurrency:YES];
}

- (NSString *)convertEthAmountToFiat
{
    app.localCurrencyFormatter.usesGroupingSeparator = NO;
    NSString *result = [NSNumberFormatter formatEthToFiat:[self.amount stringValue] exchangeRate:app.wallet.latestEthExchangeRate];
    app.localCurrencyFormatter.usesGroupingSeparator = YES;
    return result;
}

- (void)doCurrencyConversion
{
    if ([self.btcField isFirstResponder]) {
        
        NSString *result = [self convertBtcAmountToFiat];
        
        if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_ETH]) {
            self.bottomRightField.text = result;
        } else if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_BTC]) {
            self.bottomLeftField.text = result;
        }
        
    } else if ([self.ethField isFirstResponder]) {
        
        NSString *result = [self convertEthAmountToFiat];

        if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_ETH]) {
            self.bottomLeftField.text = result;
        } else if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_BTC]) {
            self.bottomRightField.text = result;
        }
        
    } else {
        
        NSString *ethString = [self.amount stringValue];
        NSString *btcString = [NSNumberFormatter formatAmount:[self.amount longLongValue] localCurrency:NO];
        
        if ([self.bottomLeftField isFirstResponder]) {
            if (self.topLeftField == self.ethField) {
                self.ethField.text = ethString;
            } else if (self.topLeftField == self.btcField) {
                self.btcField.text = btcString;
            }
        } else if ([self.bottomRightField isFirstResponder]) {
            if (self.topRightField == self.ethField) {
                self.ethField.text = ethString;
            } else if (self.topRightField == self.btcField) {
                self.btcField.text = btcString;
            }
        }
    }
    
    [self updateAvailableBalance];
    
    [self performSelector:@selector(getApproximateQuote) withObject:nil afterDelay:0.5];
}

#pragma mark - Gesture Actions

- (void)assetToggleButtonClicked
{
    if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_BTC]) {
        self.fromSymbol = CURRENCY_SYMBOL_ETH;
        self.toSymbol = CURRENCY_SYMBOL_BTC;
        
        self.ethField = self.topLeftField;
        self.btcField = self.topRightField;
        
        self.fromToView.fromLabel.text = CURRENCY_SYMBOL_ETH;
        self.fromToView.toLabel.text = CURRENCY_SYMBOL_BTC;
        
        self.leftLabel.text = CURRENCY_SYMBOL_ETH;
        self.rightLabel.text = CURRENCY_SYMBOL_BTC;
        
        self.fromAddress = [app.wallet getEtherAddress];
        self.toAddress = [app.wallet getReceiveAddressForAccount:self.btcAccount];
        
    } else if ([self.fromSymbol isEqualToString:CURRENCY_SYMBOL_ETH]) {
        self.fromSymbol = CURRENCY_SYMBOL_BTC;
        self.toSymbol = CURRENCY_SYMBOL_ETH;
        
        self.btcField = self.topLeftField;
        self.ethField = self.topRightField;
        
        self.fromToView.fromLabel.text = CURRENCY_SYMBOL_BTC;
        self.fromToView.toLabel.text = CURRENCY_SYMBOL_ETH;
        
        self.leftLabel.text = CURRENCY_SYMBOL_BTC;
        self.rightLabel.text = CURRENCY_SYMBOL_ETH;
        
        self.fromAddress = [app.wallet getReceiveAddressForAccount:self.btcAccount];
        self.toAddress = [app.wallet getEtherAddress];
    }
    
    [self getRate:[NSString stringWithFormat:@"%@_%@", self.fromSymbol, self.toSymbol]];
}

- (void)fromButtonClicked
{
    [self selectAccountClicked:SelectModeExchangeAccountFrom];
}

- (void)toButtonClicked
{
    [self selectAccountClicked:SelectModeExchangeAccountTo];
}

- (void)selectAccountClicked:(SelectMode)selectMode
{
    BCAddressSelectionView *selectorView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet selectMode:selectMode];
    selectorView.delegate = self;
    selectorView.frame = CGRectMake(0, DEFAULT_HEADER_HEIGHT, self.view.frame.size.width, self.view.frame.size.height);
    
    UIViewController *viewController = [UIViewController new];
    viewController.automaticallyAdjustsScrollViewInsets = NO;
    [viewController.view addSubview:selectorView];
    
    [self.navigationController pushViewController:viewController animated:YES];
}

- (void)useMinButtonClicked
{
    
}

- (void)useMaxButtonClicked
{
    
}

#pragma mark - Wallet actions

- (void)getRate:(NSString *)coinPair
{
    [self disableAssetToggleButton];
    [self.spinner startAnimating];
    
    [app.wallet getRate:[self coinPair]];
}

- (void)getQuote
{
    [app.wallet getQuote:[self coinPair] amount:@"0.1"];
}

- (void)getApproximateQuote
{
    [self disablePaymentButtons];
    
    if (self.currentDataTask) {
        [self.currentDataTask cancel];
        self.currentDataTask = nil;
        [self.spinner stopAnimating];
    }
    
    BOOL usingFromField = [self.topLeftField isFirstResponder] || [self.bottomLeftField isFirstResponder];

    NSString *amount;
    if ([self hasAmountGreaterThanZero:self.amount]) {

        [self disableAssetToggleButton];
        [self.spinner startAnimating];
        
        amount = [self amountString:self.amount];
        
        self.currentDataTask = [app.wallet getApproximateQuote:[self coinPair] usingFromField:usingFromField amount:amount completion:^(NSDictionary *result, NSURLResponse *response, NSError *error) {
            DLog(@"result: %@", result);
            [self didGetApproximateQuote:result];
        }];
    }
}

#pragma mark - Helpers

- (BOOL)hasAmountGreaterThanZero:(id)amount
{
    if ([amount isMemberOfClass:[NSDecimalNumber class]]) {
        return [amount compare:@0] == NSOrderedDescending;
    } else if ([amount respondsToSelector:@selector(longLongValue)]) {
        return [amount longLongValue] > 0;
    } else if (!amount) {
        DLog(@"Nil amount saved");
        return NO;
    } else {
        DLog(@"Error: unknown class for amount: %@", [self.amount class]);
        return NO;
    }
}

- (NSString *)amountString:(id)amount
{
    NSString *amountString;
    if ([self hasAmountGreaterThanZero:amount]) {
        if ([amount isMemberOfClass:[NSDecimalNumber class]]) {
            amountString = [amount stringValue];
        } else if ([amount respondsToSelector:@selector(longLongValue)]) {
            amountString = [NSNumberFormatter formatAmount:[amount longLongValue] localCurrency:NO];
        } else {
            DLog(@"Error: unknown class for amount: %@", [amount class]);
        }
    }
    
    return amountString;
}

- (BCSecureTextField *)inputTextFieldWithFrame:(CGRect)frame
{
    BCSecureTextField *textField = [[BCSecureTextField alloc] initWithFrame:frame];
    textField.keyboardType = UIKeyboardTypeDecimalPad;
    textField.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    textField.textColor = COLOR_TEXT_DARK_GRAY;
    textField.delegate = self;
    return textField;
}

- (NSString *)coinPair
{
    return [NSString stringWithFormat:@"%@_%@", self.fromSymbol, self.toSymbol];
}

- (void)enableAssetToggleButton
{
    self.assetToggleButton.userInteractionEnabled = YES;
    [self.assetToggleButton setImage:[UIImage imageNamed:IMAGE_NAME_SWITCH_CURRENCIES] forState:UIControlStateNormal];
}

- (void)disableAssetToggleButton
{
    self.assetToggleButton.userInteractionEnabled = NO;
    [self.assetToggleButton setImage:nil forState:UIControlStateNormal];
}

#pragma mark - Address Selection Delegate

- (void)didSelectFromEthAccount
{
    [self.navigationController popViewControllerAnimated:YES];
    
    self.fromToView.fromLabel.text = [app.wallet getLabelForEthAccount];
    self.fromToView.toLabel.text = [app.wallet getLabelForAccount:self.btcAccount];
}

- (void)didSelectToEthAccount
{
    [self.navigationController popViewControllerAnimated:YES];
    
    self.fromToView.fromLabel.text = [app.wallet getLabelForAccount:self.btcAccount];
    self.fromToView.toLabel.text = [app.wallet getLabelForEthAccount];
}

- (void)didSelectFromAccount:(int)account
{
    [self.navigationController popViewControllerAnimated:YES];
    
    self.btcAccount = account;
    self.fromToView.fromLabel.text = [app.wallet getLabelForAccount:self.btcAccount];
    self.fromToView.toLabel.text = [app.wallet getLabelForEthAccount];
}

- (void)didSelectToAccount:(int)account
{
    [self.navigationController popViewControllerAnimated:YES];
    
    self.btcAccount = account;
    self.fromToView.fromLabel.text = [app.wallet getLabelForEthAccount];
    self.fromToView.toLabel.text = [app.wallet getLabelForAccount:self.btcAccount];
}

- (void)didSelectToAddress:(NSString *)address
{
    // required by protocol
}

- (void)didSelectContact:(Contact *)contact
{
    // required by protocol
}

- (void)didSelectFromAddress:(NSString *)address
{
    // required by protocol
}

#pragma mark - Continue Button Input Accessory View Delegate

- (void)continueButtonClicked
{
    BOOL fromBtc = [self.fromSymbol isEqualToString:CURRENCY_SYMBOL_BTC];
    int fromAccount = fromBtc ? self.btcAccount : 0;
    int toAccount = fromBtc ? self.btcAccount : 0;
    NSString *fee = fromBtc ? [NSString stringWithFormat:@"%lld", [self.fee longLongValue]] : [self amountString:self.fee];
    
    [app.wallet buildExchangeTradeFromAccount:fromAccount toAccount:toAccount coinPair:[self coinPair] amount:[self amountString:self.amount] fee:fee];
}

- (void)closeButtonClicked
{
    [self.topLeftField resignFirstResponder];
    [self.topRightField resignFirstResponder];
    [self.bottomLeftField resignFirstResponder];
    [self.bottomRightField resignFirstResponder];
}

@end

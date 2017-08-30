//
//  SendEtherViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/21/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SendEtherViewController.h"
#import "BCLine.h"
#import "UIView+ChangeFrameAttribute.h"
#import "Blockchain-Swift.h"
#import "BCAmountInputView.h"
#import "RootService.h"
#import "BCConfirmPaymentView.h"
#import "BCConfirmPaymentViewModel.h"

@interface EtherAmountInputViewController ()
@property (nonatomic) NSDecimalNumber *latestExchangeRate;
@property (nonatomic) BCAmountInputView *amountInputView;
@property (nonatomic) UITextField *toField;
@property (nonatomic) NSDecimalNumber *ethAmount;
- (void)doCurrencyConversion;
@end

@interface SendEtherViewController () <ConfirmPaymentViewDelegate>
@property (nonatomic) NSDecimalNumber *ethFee;
@property (nonatomic) UILabel *feeAmountLabel;
@property (nonatomic) UIButton *fundsAvailableButton;
@property (nonatomic) UIButton *continuePaymentButton;
@property (nonatomic) UIButton *continuePaymentAccessoryButton;
@property (nonatomic) BCConfirmPaymentView *confirmPaymentView;

@end

@implementation SendEtherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat statusBarAdjustment = [[UIApplication sharedApplication] statusBarFrame].size.height > DEFAULT_STATUS_BAR_HEIGHT ? DEFAULT_STATUS_BAR_HEIGHT : 0;

    self.view.frame = CGRectMake(0,
                                 TAB_HEADER_HEIGHT_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET - DEFAULT_HEADER_HEIGHT,
                                 [UIScreen mainScreen].bounds.size.width,
                                 [UIScreen mainScreen].bounds.size.height - (TAB_HEADER_HEIGHT_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET) - DEFAULT_FOOTER_HEIGHT - statusBarAdjustment);
    
    BCLine *lineAboveToField = [self offsetLineWithYPosition:0];
    [self.view addSubview:lineAboveToField];
    
    UILabel *toLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 15, 40, 21)];
    toLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    toLabel.textColor = COLOR_TEXT_DARK_GRAY;
    toLabel.text = BC_STRING_TO;
    [self.view addSubview:toLabel];
    
    BCSecureTextField *toField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(toLabel.frame.origin.x + toLabel.frame.size.width + 8, 6, 222, 39)];
    toField.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    toField.placeholder = BC_STRING_ENTER_ETHER_ADDRESS_OR_SELECT;
    toField.delegate = self;
    toField.textColor = COLOR_TEXT_DARK_GRAY;
    toField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.view addSubview:toField];
    self.toField = toField;
    
    BCLine *lineBelowToField = [self offsetLineWithYPosition:51];
    [self.view addSubview:lineBelowToField];

    BCAmountInputView *amountInputView = [[BCAmountInputView alloc] init];
    amountInputView.btcLabel.text = CURRENCY_SYMBOL_ETH;
    [amountInputView changeYPosition:51];
    [amountInputView changeHeight:amountInputView.btcLabel.frame.origin.y + amountInputView.btcLabel.frame.size.height];
    [self.view addSubview:amountInputView];
    UIView *inputAccessoryView = [self getInputAccessoryView];
    toField.inputAccessoryView = inputAccessoryView;
    amountInputView.btcField.inputAccessoryView = inputAccessoryView;
    amountInputView.fiatField.inputAccessoryView = inputAccessoryView;
    amountInputView.btcField.delegate = self;
    amountInputView.fiatField.delegate = self;
    self.amountInputView = amountInputView;
    
    CGFloat useAllButtonOriginY = amountInputView.frame.origin.y + amountInputView.frame.size.height;
    UIButton *fundsAvailableButton = [[UIButton alloc] initWithFrame:CGRectMake(15, useAllButtonOriginY, self.view.frame.size.width - 15 - 8, 112 -useAllButtonOriginY)];
    fundsAvailableButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    [fundsAvailableButton setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateNormal];
    fundsAvailableButton.titleLabel.textAlignment = NSTextAlignmentLeft;
    fundsAvailableButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
    fundsAvailableButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.fundsAvailableButton = fundsAvailableButton;
    
    [self.view addSubview:fundsAvailableButton];

    BCLine *lineBelowAmounts = [self offsetLineWithYPosition:112];
    [self.view addSubview:lineBelowAmounts];
    
    UILabel *feeLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 112 + 15, 40, 21)];
    feeLabel.textColor = COLOR_TEXT_DARK_GRAY;
    feeLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    feeLabel.text = BC_STRING_FEE;
    [self.view addSubview:feeLabel];
    
    UILabel *feeAmountLabel = [[UILabel alloc] initWithFrame:CGRectMake(feeLabel.frame.origin.x + feeLabel.frame.size.width + 8, 112 + 6, 222, 39)];
    feeAmountLabel.textColor = COLOR_TEXT_DARK_GRAY;
    feeAmountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    [self.view addSubview:feeAmountLabel];
    self.feeAmountLabel = feeAmountLabel;

    BCLine *lineBelowFee = [self offsetLineWithYPosition:163];
    [self.view addSubview:lineBelowFee];
    
    CGFloat spacing = 12;
    CGFloat sendButtonOriginY = self.view.frame.size.height - BUTTON_HEIGHT - spacing;
    UIButton *continueButton = [[UIButton alloc] initWithFrame:CGRectMake(0, sendButtonOriginY, self.view.frame.size.width - 40, BUTTON_HEIGHT)];
    continueButton.center = CGPointMake(self.view.center.x, continueButton.center.y);
    [continueButton setTitle:BC_STRING_CONTINUE forState:UIControlStateNormal];
    continueButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    continueButton.layer.cornerRadius = CORNER_RADIUS_BUTTON;
    continueButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
    [continueButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [continueButton addTarget:self action:@selector(continueButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:continueButton];
    self.continuePaymentButton = continueButton;
}

- (void)reload
{
    [app.wallet createNewEtherPayment];
    
    [app.wallet getEthExchangeRate];
}

- (void)getHistory
{
    [app.wallet getEthHistory];
}

- (void)updateExchangeRate:(NSDecimalNumber *)rate
{
    self.latestExchangeRate = rate;
    
    [self doCurrencyConversion];
}

- (void)doCurrencyConversion
{
    [super doCurrencyConversion];
    
    [app.wallet changeEtherPaymentAmount:self.ethAmount];
}

- (void)didUpdatePayment:(NSDictionary *)payment;
{
    id dictAmount = payment[DICTIONARY_KEY_AMOUNT];
    id dictAvailable = payment[DICTIONARY_KEY_AVAILABLE];
    id dictFee = payment[DICTIONARY_KEY_FEE];
    
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:[dictAmount decimalValue]];
    DLog(@"Amount is %@", amount);
    self.ethAmount = amount;
    
    NSDecimalNumber *available = [NSDecimalNumber decimalNumberWithDecimal:[dictAvailable decimalValue]];
    NSDecimalNumber *fee = [NSDecimalNumber decimalNumberWithDecimal:[dictFee decimalValue]];
    
    [self.fundsAvailableButton setTitle:[NSString stringWithFormat:BC_STRING_USE_TOTAL_AVAILABLE_MINUS_FEE_ARGUMENT, available] forState:UIControlStateNormal];
    
    self.ethFee = fee;
    self.feeAmountLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", fee, CURRENCY_SYMBOL_ETH,
                                [NSNumberFormatter formatEthToFiatWithSymbol:[fee stringValue] exchangeRate:self.latestExchangeRate]];
    
    if ([available compare:amount] == NSOrderedDescending) {
        [self enablePaymentButtons];
    } else {
        [self disablePaymentButtons];
    }
}

- (void)selectToAddress:(NSString *)address
{
    self.toField.text = address;
    [app.wallet changeEtherPaymentTo:address];
}

- (void)disablePaymentButtons
{
    self.continuePaymentButton.enabled = NO;
    [self.continuePaymentButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.continuePaymentButton setBackgroundColor:COLOR_BUTTON_KEYPAD_GRAY];
    
    self.continuePaymentAccessoryButton.enabled = NO;
    [self.continuePaymentAccessoryButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.continuePaymentAccessoryButton setBackgroundColor:COLOR_BUTTON_KEYPAD_GRAY];
}

- (void)enablePaymentButtons
{
    self.continuePaymentButton.enabled = YES;
    [self.continuePaymentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.continuePaymentButton setBackgroundColor:COLOR_BLOCKCHAIN_LIGHT_BLUE];
    
    [self.continuePaymentAccessoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    self.continuePaymentAccessoryButton.enabled = YES;
    [self.continuePaymentAccessoryButton setBackgroundColor:COLOR_BLOCKCHAIN_LIGHT_BLUE];
}

#pragma mark - View Helpers

- (BCLine *)offsetLineWithYPosition:(CGFloat)yPosition
{
    BCLine *line = [[BCLine alloc] initWithYPosition:yPosition];
    [line changeXPosition:15];
    return line;
}

- (UIView *)getInputAccessoryView
{
    UIView *inputAccessoryView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, BUTTON_HEIGHT)];
    
    UIButton *continueButton = [[UIButton alloc] initWithFrame:inputAccessoryView.bounds];
    [continueButton setTitle:BC_STRING_CONTINUE forState:UIControlStateNormal];
    continueButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_LARGE];
    [continueButton addTarget:self action:@selector(continueButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    continueButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    [inputAccessoryView addSubview:continueButton];
    self.continuePaymentAccessoryButton = continueButton;
    
    CGFloat closeButtonWidth = 50;
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(inputAccessoryView.bounds.size.width - closeButtonWidth, 0, closeButtonWidth, BUTTON_HEIGHT)];
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(hideKeyboard) forControlEvents:UIControlEventTouchUpInside];
    closeButton.backgroundColor = COLOR_BUTTON_DARK_GRAY;
    [inputAccessoryView addSubview:closeButton];
    
    return inputAccessoryView;
}

- (void)continueButtonClicked
{
    NSDecimalNumber *totalDecimalNumber = [self.ethAmount decimalNumberByAdding:self.ethFee];
    
    BCConfirmPaymentViewModel *confirmPaymentViewModel = [[BCConfirmPaymentViewModel alloc]
                                                          initWithTo:self.toField.text
                                                          ethAmount:[NSNumberFormatter formatEth:self.ethAmount]
                                                          ethFee:[NSNumberFormatter formatEth:self.ethFee]
                                                          ethTotal:[NSNumberFormatter formatEth:totalDecimalNumber]
                                                          fiatAmount:[NSNumberFormatter appendStringToFiatSymbol:self.amountInputView.fiatField.text]
                                                          fiatFee:[NSNumberFormatter formatEthToFiatWithSymbol:[self.ethFee stringValue] exchangeRate:self.latestExchangeRate]
                                                          fiatTotal:[NSNumberFormatter formatEthToFiatWithSymbol:[NSString stringWithFormat:@"%@", totalDecimalNumber] exchangeRate:self.latestExchangeRate]];
    
    self.confirmPaymentView = [[BCConfirmPaymentView alloc] initWithWindow:self.view.window viewModel:confirmPaymentViewModel];
    self.confirmPaymentView.confirmDelegate = self;
    
    [app showModalWithContent:self.confirmPaymentView closeType:ModalCloseTypeBack headerText:BC_STRING_CONFIRM_PAYMENT];
}

- (void)setupNoteForTransaction:(NSString *)note
{
    DLog(@"Not setting up note - Ether payment");
}

- (void)feeInformationButtonClicked
{
    
}

- (void)hideKeyboard
{
    [self.toField resignFirstResponder];
    [self.amountInputView.fiatField resignFirstResponder];
    [self.amountInputView.btcField resignFirstResponder];
}

- (BOOL)isEtherAddress:(NSString *)address
{
    return [app.wallet isEthAddress:address];
}

@end

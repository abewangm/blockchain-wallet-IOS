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

@interface QRCodeScannerSendViewController ()
- (void)stopReadingQRCode;
@end

@interface EtherAmountInputViewController ()
@property (nonatomic) NSString *toAddress;
@property (nonatomic) NSDecimalNumber *latestExchangeRate;
@property (nonatomic) BCAmountInputView *amountInputView;
@property (nonatomic) UITextField *toField;
@property (nonatomic) NSDecimalNumber *ethAmount;
@property (nonatomic) NSDecimalNumber *ethAvailable;
@property (nonatomic) BOOL displayingLocalSymbolSend;

- (void)doCurrencyConversion;
@end

@interface SendEtherViewController () <ConfirmPaymentViewDelegate>
@property (nonatomic) NSDecimalNumber *ethFee;
@property (nonatomic) UILabel *feeAmountLabel;
@property (nonatomic) UIButton *fundsAvailableButton;
@property (nonatomic) UIButton *continuePaymentButton;
@property (nonatomic) NSString *noteToSet;
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
    
    CGFloat toFieldOriginX = toLabel.frame.origin.x + toLabel.frame.size.width + 8;
    BCSecureTextField *toField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(toFieldOriginX, 6, self.view.frame.size.width - 8 - toFieldOriginX, 39)];
    toField.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    toField.placeholder = BC_STRING_ENTER_ETHER_ADDRESS;
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
    fundsAvailableButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [fundsAvailableButton setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateNormal];
    fundsAvailableButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_EXTRA_EXTRA_SMALL];
    fundsAvailableButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [fundsAvailableButton addTarget:self action:@selector(useAllClicked) forControlEvents:UIControlEventTouchUpInside];
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

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self getHistory];
}

- (void)reload
{
    [app.wallet createNewEtherPayment];

    if (self.addressToSet) {
        [self selectToAddress:self.addressToSet];
        self.addressToSet = nil;
    } else {
        self.toAddress = nil;
        self.toField.text = nil;
    }
    
    [self.amountInputView clearFields];
    
    [app.wallet getEthExchangeRate];
}

- (void)setAddress:(NSString *)address
{
    [self selectToAddress:address];
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
    BOOL dictSweep = [payment[DICTIONARY_KEY_SWEEP] boolValue];
    
    NSDecimalNumber *amount = [NSDecimalNumber decimalNumberWithDecimal:[dictAmount decimalValue]];
    DLog(@"Amount is %@", amount);
    self.ethAmount = amount;
    
    NSDecimalNumber *available = [NSDecimalNumber decimalNumberWithDecimal:[dictAvailable decimalValue]];
    NSDecimalNumber *fee = [NSDecimalNumber decimalNumberWithDecimal:[dictFee decimalValue]];
    
    if (dictSweep) {
        self.amountInputView.btcField.text = [amount compare:@0] == NSOrderedSame ? nil : [amount stringValue];
        self.amountInputView.fiatField.text = [NSNumberFormatter formatEthToFiat:[amount stringValue] exchangeRate:self.latestExchangeRate];
    }
    
    self.ethAvailable = available;
    
    self.ethFee = fee;
    self.feeAmountLabel.text = [NSString stringWithFormat:@"%@ %@ (%@)", fee, CURRENCY_SYMBOL_ETH,
                                [NSNumberFormatter formatEthToFiatWithSymbol:[fee stringValue] exchangeRate:self.latestExchangeRate]];

    if ([app.wallet isWaitingOnEtherTransaction]) {
        [self.fundsAvailableButton setTitle:BC_STRING_WAITING_FOR_ETHER_PAYMENT_TO_FINISH_MESSAGE forState:UIControlStateNormal];
        [self.fundsAvailableButton setTitleColor:COLOR_WARNING_RED forState:UIControlStateNormal];
        self.toField.userInteractionEnabled = NO;
        self.fundsAvailableButton.userInteractionEnabled = NO;
        self.amountInputView.userInteractionEnabled = NO;
        [self disablePaymentButtons];
        return;
    } else {
        [self.fundsAvailableButton setTitle:[NSString stringWithFormat:BC_STRING_USE_TOTAL_AVAILABLE_MINUS_FEE_ARGUMENT, [NSString stringWithFormat:@"%@ %@", available, CURRENCY_SYMBOL_ETH]] forState:UIControlStateNormal];
        [self.fundsAvailableButton setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateNormal];
        self.toField.userInteractionEnabled = YES;
        self.fundsAvailableButton.userInteractionEnabled = YES;
        self.amountInputView.userInteractionEnabled = YES;
    }
    
    NSComparisonResult result = [available compare:amount];
    
    if (result == NSOrderedDescending || result == NSOrderedSame) {
        [self enablePaymentButtons];
    } else {
        [self disablePaymentButtons];
    }
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

- (void)useAllClicked
{
    [app.wallet sweepEtherPayment];
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
    if (self.toAddress == nil || ![self isEtherAddress:self.toAddress]) {
        [app standardNotify:[NSString stringWithFormat:BC_STRING_INVALID_ETHER_ADDRESS_ARGUMENT, self.toAddress]];
        return;
    }
    
    [self checkIfEtherContractAddress:self.toAddress successHandler:^(NSString *nonContractAddress) {
        
        [app.wallet changeEtherPaymentTo:nonContractAddress];

        NSDecimalNumber *totalDecimalNumber = [self.ethAmount decimalNumberByAdding:self.ethFee];
        
        BCConfirmPaymentViewModel *confirmPaymentViewModel = [[BCConfirmPaymentViewModel alloc]
                                                              initWithTo:self.toAddress
                                                              ethAmount:[NSNumberFormatter formatEth:self.ethAmount]
                                                              ethFee:[NSNumberFormatter formatEth:self.ethFee]
                                                              ethTotal:[NSNumberFormatter formatEth:totalDecimalNumber]
                                                              fiatAmount:[NSNumberFormatter appendStringToFiatSymbol:self.amountInputView.fiatField.text]
                                                              fiatFee:[NSNumberFormatter formatEthToFiatWithSymbol:[self.ethFee stringValue] exchangeRate:self.latestExchangeRate]
                                                              fiatTotal:[NSNumberFormatter formatEthToFiatWithSymbol:[NSString stringWithFormat:@"%@", totalDecimalNumber] exchangeRate:self.latestExchangeRate]];
        
        self.confirmPaymentView = [[BCConfirmPaymentView alloc] initWithWindow:self.view.window viewModel:confirmPaymentViewModel];
        self.confirmPaymentView.confirmDelegate = self;
        
        [self.confirmPaymentView.reallyDoPaymentButton addTarget:self action:@selector(reallyDoPayment) forControlEvents:UIControlEventTouchUpInside];
        
        [app showModalWithContent:self.confirmPaymentView closeType:ModalCloseTypeBack headerText:BC_STRING_CONFIRM_PAYMENT];
    }];
}

- (void)setupNoteForTransaction:(NSString *)note
{
    self.noteToSet = note;
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

- (void)reallyDoPayment
{
    if ([self checkIfWaitingOnEtherTransaction]) return;
    
    UIView *sendView = [[UIView alloc] initWithFrame:self.view.frame];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0, 60, 20, 20)];
    spinner.activityIndicatorViewStyle = UIActivityIndicatorViewStyleGray;
    spinner.center = CGPointMake(self.view.center.x, spinner.center.y);
    [spinner startAnimating];
    [sendView addSubview:spinner];
    
    UILabel *sendLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 90, 240, 120)];
    sendLabel.textAlignment = NSTextAlignmentCenter;
    sendLabel.center = CGPointMake(self.view.center.x, sendLabel.center.y);
    sendLabel.textColor = COLOR_TEXT_DARK_GRAY;
    sendLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
    sendLabel.text = BC_STRING_SENDING;
    [sendView addSubview:sendLabel];
    
    [app showModalWithContent:sendView closeType:ModalCloseTypeNone headerText:BC_STRING_SENDING_TRANSACTION];
    
    [app.wallet sendEtherPaymentWithNote:self.noteToSet];
}

- (BOOL)checkIfWaitingOnEtherTransaction
{
    BOOL isWaiting = [app.wallet isWaitingOnEtherTransaction];
    
    if (isWaiting) {
        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:BC_STRING_WAITING_FOR_ETHER_PAYMENT_TO_FINISH_TITLE message:BC_STRING_WAITING_FOR_ETHER_PAYMENT_TO_FINISH_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
        [errorAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        [self.view.window.rootViewController presentViewController:errorAlert animated:YES completion:nil];
    }
    
    return isWaiting;
}

#pragma mark - Text Field Delegate

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    [super textFieldDidBeginEditing:textField];
    
    NSString *availableAmount;
    
    if (self.displayingLocalSymbolSend) {
        availableAmount = [NSNumberFormatter formatEthToFiatWithSymbol:[self.ethAvailable stringValue] exchangeRate:self.latestExchangeRate];
    } else {
        availableAmount = [NSNumberFormatter formatEth:self.ethAvailable];
    }
    
    [self.fundsAvailableButton setTitle:[NSString stringWithFormat:BC_STRING_USE_TOTAL_AVAILABLE_MINUS_FEE_ARGUMENT, availableAmount] forState:UIControlStateNormal];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects firstObject];
        
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self performSelectorOnMainThread:@selector(stopReadingQRCode) withObject:nil waitUntilDone:NO];
            
            // do something useful with results
            dispatch_sync(dispatch_get_main_queue(), ^{

                NSString *address = [metadataObj stringValue];
                
                [self selectToAddress:address];
                DLog(@"toAddress: %@", address);
                
            });
        }
    }
}

#pragma mark - Overrides

- (BOOL)isEtherAddress:(NSString *)address
{
    return [app.wallet isEthAddress:address];
}

- (void)selectToAddress:(NSString *)address
{
    if (address == nil || ![self isEtherAddress:address]) {
        [app standardNotify:[NSString stringWithFormat:BC_STRING_INVALID_ETHER_ADDRESS_ARGUMENT, address]];
        return;
    }
    
    self.toField.text = address;
    self.toAddress = address;
    
    [self checkIfEtherContractAddress:address successHandler:nil];
}

- (void)checkIfEtherContractAddress:(NSString *)address successHandler:(void (^ _Nullable)(NSString *))success
{
    [app.wallet isEtherContractAddress:address completion:^(NSData *data, NSURLResponse *response, NSError *error) {
        NSError *jsonError;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
        BOOL isContract = [[[jsonResponse allValues] firstObject] boolValue];
        if (isContract) {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_CONTRACT_ADDRESSES_NOT_SUPPORTED_TITLE message:BC_STRING_CONTRACT_ADDRESSES_NOT_SUPPORTED_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction: [UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
            [app.tabControllerManager.tabViewController presentViewController:alert animated:YES completion:nil];
        } else {
            if (success) success(address);
        }
    }];
}

@end

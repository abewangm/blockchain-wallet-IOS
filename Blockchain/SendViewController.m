//
//  SendViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "SendViewController.h"
#import "Wallet.h"
#import "AppDelegate.h"
#import "BCAddressSelectionView.h"
#import "TabViewController.h"
#import "UncaughtExceptionHandler.h"
#import "UITextField+Blocks.h"
#import "UIViewController+AutoDismiss.h"
#import "LocalizationConstants.h"
#import "TransactionsViewController.h"
#import "PrivateKeyReader.h"

@interface SendViewController () <UITextFieldDelegate>

@property (nonatomic) uint64_t recommendedForcedFee;
@property (nonatomic) uint64_t maxSendableAmount;
@property (nonatomic) uint64_t feeFromTransactionProposal;

@property (nonatomic) uint64_t amountFromURLHandler;

@property (nonatomic) NSDictionary *recommendedFees;
@property (nonatomic) BOOL isSurgeOccurring;
@property (nonatomic) uint64_t upperRecommendedLimit;
@property (nonatomic) uint64_t lowerRecommendedLimit;
@property (nonatomic) uint64_t estimatedTransactionSize;
@property (nonatomic) BOOL customFeeMode;

@property (nonatomic, copy) void (^getTransactionFeeSuccess)();
@property (nonatomic, copy) void (^getDynamicFeeError)();

@end

@implementation SendViewController

AVCaptureSession *captureSession;
AVCaptureVideoPreviewLayer *videoPreviewLayer;

float containerOffset;

uint64_t amountInSatoshi = 0.0;
uint64_t availableAmount = 0.0;

BOOL displayingLocalSymbolSend;

#pragma mark - Lifecycle

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    CGFloat statusBarAdjustment = [[UIApplication sharedApplication] statusBarFrame].size.height > DEFAULT_STATUS_BAR_HEIGHT ? DEFAULT_STATUS_BAR_HEIGHT : 0;
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT - statusBarAdjustment);
    
    sendProgressModalText.text = nil;
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_LOADING_TEXT object:nil queue:nil usingBlock:^(NSNotification * notification) {
        
        sendProgressModalText.text = [notification object];
    }];
    
    app.mainTitleLabel.text = BC_STRING_SEND;
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_LOADING_TEXT object:nil];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // force Payment initialization in JS
    [self resetPayment];
    
    btcAmountField.inputAccessoryView = amountKeyboardAccessoryView;
    fiatAmountField.inputAccessoryView = amountKeyboardAccessoryView;
    toField.inputAccessoryView = amountKeyboardAccessoryView;
    feeField.inputAccessoryView = amountKeyboardAccessoryView;
    
    feeField.delegate = self;
    
    btcAmountField.placeholder = [NSString stringWithFormat:BTC_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    fiatAmountField.placeholder = [NSString stringWithFormat:FIAT_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    
    [toField setReturnKeyType:UIReturnKeyDone];
    
    [self reload];
}

- (void)resetPayment
{
    [app.wallet createNewPayment];
    [app.wallet changePaymentFromAddress:@""];
    if (app.tabViewController.activeViewController == self) {
        [app closeModalWithTransition:kCATransitionPush];
    }
}

- (void)resetFromAddress
{
    self.fromAddress = @"";
    if ([app.wallet hasAccount]) {
        // Default setting: send from default account
        self.sendFromAddress = false;
        int defaultAccountIndex = [app.wallet getDefaultAccountIndexActiveOnly:YES];
        self.fromAccount = defaultAccountIndex;
        [app.wallet createNewPayment];
        [self didSelectFromAccount:self.fromAccount];
    }
    else {
        // Default setting: send from any address
        self.sendFromAddress = true;
        [self resetPayment];
    }
}

- (void)clearToAddressAndAmountFields
{
    self.toAddress = @"";
    toField.text = @"";
    amountInSatoshi = 0;
    btcAmountField.text = @"";
    fiatAmountField.text = @"";
    feeField.text = @"";
}

- (void)reload
{
    [self clearToAddressAndAmountFields];

    if (![app.wallet isInitialized]) {
        DLog(@"SendViewController: Wallet not initialized");
        return;
    }
    
    if (!app.latestResponse) {
        DLog(@"SendViewController: No latest response");
        return;
    }
    
    [self resetPayment];
    
    [self resetFromAddress];
    
    // Default: send to address
    self.sendToAddress = true;
    
    [self hideSelectFromAndToButtonsIfAppropriate];
    
    [self populateFieldsFromURLHandlerIfAvailable];
    
    [self reloadFromAndToFields];
    
    [self reloadLocalAndBtcSymbolsFromLatestResponse];
    
    [self updateFundsAvailable];
    
    [self enablePaymentButtons];
    
    self.recommendedFees = nil;
    
    [self changeToDefaultFeeMode];
}

- (void)hideSelectFromAndToButtonsIfAppropriate
{
    // If we only have one account and no legacy addresses -> can't change from address
    if ([app.wallet hasAccount] && ![app.wallet hasLegacyAddresses]
        && [app.wallet getActiveAccountsCount] == 1) {
        
        [selectFromButton setHidden:YES];
        
        if ([app.wallet addressBook].count == 0) {
            [addressBookButton setHidden:YES];
        } else {
            [addressBookButton setHidden:NO];
        }
    }
    else {
        [selectFromButton setHidden:NO];
        [addressBookButton setHidden:NO];
    }
}

- (void)populateFieldsFromURLHandlerIfAvailable
{
    if (self.addressFromURLHandler && toField != nil) {
        self.sendToAddress = true;
        self.toAddress = self.addressFromURLHandler;
        DLog(@"toAddress: %@", self.toAddress);
        
        toField.text = [self labelForLegacyAddress:self.toAddress];
        self.addressFromURLHandler = nil;
        
        amountInSatoshi = self.amountFromURLHandler;
        [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
        self.amountFromURLHandler = 0;
    }
}

- (void)reloadFromAndToFields
{
    [self reloadFromField];
    [self reloadToField];
}

- (void)reloadFromField
{
    if (self.sendFromAddress) {
        if (self.fromAddress.length == 0) {
            selectAddressTextField.text = BC_STRING_ANY_ADDRESS;
            availableAmount = [app.wallet getTotalBalanceForActiveLegacyAddresses];
        }
        else {
            selectAddressTextField.text = [self labelForLegacyAddress:self.fromAddress];
            availableAmount = [app.wallet getLegacyAddressBalance:self.fromAddress];
        }
    }
    else {
        selectAddressTextField.text = [app.wallet getLabelForAccount:self.fromAccount activeOnly:YES];
        availableAmount = [app.wallet getBalanceForAccount:self.fromAccount activeOnly:YES];
    }
}

- (void)reloadToField
{
    if (self.sendToAddress) {
        toField.text = [self labelForLegacyAddress:self.toAddress];
        if ([app.wallet isBitcoinAddress:toField.text]) {
            [self didSelectToAddress:self.toAddress];
        } else {
            toField.text = @"";
            self.toAddress = @"";
        }
    }
    else {
        toField.text = [app.wallet getLabelForAccount:self.toAccount activeOnly:YES];
        [self didSelectToAccount:self.toAccount];
    }
}

- (void)reloadLocalAndBtcSymbolsFromLatestResponse
{
    if (app.latestResponse.symbol_local && app.latestResponse.symbol_btc) {
        fiatLabel.text = app.latestResponse.symbol_local.code;
        btcLabel.text = app.latestResponse.symbol_btc.symbol;
    }
    
    if (app->symbolLocal && app.latestResponse.symbol_local && app.latestResponse.symbol_local.conversion > 0) {
        displayingLocalSymbol = TRUE;
        displayingLocalSymbolSend = TRUE;
    } else if (app.latestResponse.symbol_btc) {
        displayingLocalSymbol = FALSE;
        displayingLocalSymbolSend = FALSE;
    }
}

#pragma mark - Payment

- (IBAction)reallyDoPayment:(id)sender
{
    if (![app checkInternetConnection]) {
        return;
    }
    
    if (self.sendFromAddress && [app.wallet isWatchOnlyLegacyAddress:self.fromAddress]) {
        
        [self alertUserForSpendingFromWatchOnlyAddress];
    
        return;
    } else {
        [self sendPaymentWithListener];
    }
}

- (void)sendFromWatchOnlyAddress
{
    [self sendPaymentWithListener];
}

- (void)sendPaymentWithListener
{
    transactionProgressListeners *listener = [[transactionProgressListeners alloc] init];
    
    listener.on_start = ^() {
    };
    
    listener.on_begin_signing = ^() {
        sendProgressModalText.text = BC_STRING_SIGNING_INPUTS;
    };
    
    listener.on_sign_progress = ^(int input) {
        DLog(@"Signing input: %d", input);
        sendProgressModalText.text = [NSString stringWithFormat:BC_STRING_SIGNING_INPUT, input];
    };
    
    listener.on_finish_signing = ^() {
        sendProgressModalText.text = BC_STRING_FINISHED_SIGNING_INPUTS;
    };
    
    listener.on_success = ^() {
        
        DLog(@"SendViewController: on_success");
        
        [app standardNotify:BC_STRING_PAYMENT_SENT title:BC_STRING_SUCCESS delegate:nil];
        
        [sendProgressActivityIndicator stopAnimating];
        
        [self enablePaymentButtons];
        
        // Fields are automatically reset by reload, called by MyWallet.wallet.getHistory() after a utx websocket message is received. However, we cannot rely on the websocket 100% of the time.
        [app.wallet performSelector:@selector(getHistoryIfNoTransactionMessage) withObject:nil afterDelay:DELAY_GET_HISTORY_BACKUP];
        
        // Close transaction modal, go to transactions view, scroll to top and animate new transaction
        [app closeModalWithTransition:kCATransitionFade];
        [app.transactionsViewController animateNextCellAfterReload];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [app transactionsClicked:nil];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [app.transactionsViewController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
        });
    };
    
    listener.on_error = ^(NSString* error) {
        DLog(@"Send error: %@", error);

        if ([error isEqualToString:ERROR_UNDEFINED]) {
            [app standardNotify:BC_STRING_SEND_ERROR_NO_INTERNET_CONNECTION];
        } else if (error && error.length != 0)  {
            [app standardNotify:error];
        }
        
        [sendProgressActivityIndicator stopAnimating];
        
        [self enablePaymentButtons];
        
        [app closeModalWithTransition:kCATransitionFade];
        
        [self reload];
        
        [app.wallet getHistory];
    };
    
    [self disablePaymentButtons];
    
    [sendProgressActivityIndicator startAnimating];
    
    sendProgressModalText.text = BC_STRING_SENDING_TRANSACTION;
    
    [app showModalWithContent:sendProgressModal closeType:ModalCloseTypeNone headerText:BC_STRING_SENDING_TRANSACTION];
    
    NSString *amountString;
    amountString = [[NSNumber numberWithLongLong:amountInSatoshi] stringValue];
    
    DLog(@"Sending uint64_t %llu Satoshi (String value: %@)", amountInSatoshi, amountString);
    
    // Different ways of sending (from/to address or account
    if (self.sendFromAddress && self.sendToAddress) {
        DLog(@"From: %@", self.fromAddress);
        DLog(@"To: %@", self.toAddress);
    }
    else if (self.sendFromAddress && !self.sendToAddress) {
        DLog(@"From: %@", self.fromAddress);
        DLog(@"To account: %d", self.toAccount);
    }
    else if (!self.sendFromAddress && self.sendToAddress) {
        DLog(@"From account: %d", self.fromAccount);
        DLog(@"To: %@", self.toAddress);
    }
    else if (!self.sendFromAddress && !self.sendToAddress) {
        DLog(@"From account: %d", self.fromAccount);
        DLog(@"To account: %d", self.toAccount);
    }
    
    app.wallet.didReceiveMessageForLastTransaction = NO;
    
    [app.wallet sendPaymentWithListener:listener];
}

- (uint64_t)getInputAmountInSatoshi
{
    NSString *amountString = [btcAmountField.text stringByReplacingOccurrencesOfString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator] withString:@"."];
    
    if (displayingLocalSymbol) {
        return app.latestResponse.symbol_local.conversion * [amountString doubleValue];
    } else {
        return [app.wallet parseBitcoinValue:amountString];
    }
}

- (void)showSweepConfirmationScreenWithMaxAmount:(uint64_t)maxAmount
{
    [self hideKeyboard];
    
    // Timeout so the keyboard is fully dismised - otherwise the second password modal keyboard shows the send screen kebyoard accessory
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        self.maxSendableAmount = maxAmount;
        
        uint64_t spendableAmount = maxAmount + self.feeFromTransactionProposal;
        
        NSString *wantToSendAmountString = [app formatMoney:amountInSatoshi localCurrency:NO];
        NSString *spendableAmountString = [app formatMoney:spendableAmount localCurrency:NO];
        NSString *feeAmountString = [app formatMoney:self.feeFromTransactionProposal localCurrency:NO];
        
        NSString *canSendAmountString = [app formatMoney:maxAmount localCurrency:NO];
        
        NSString *sweepMessageString = [[NSString alloc] initWithFormat:BC_STRING_CONFIRM_SWEEP_MESSAGE_WANT_TO_SEND_ARGUMENT_BALANCE_MINUS_FEE_ARGUMENT_ARGUMENT_SEND_ARGUMENT, wantToSendAmountString, spendableAmountString, feeAmountString, canSendAmountString];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_CONFIRM_SWEEP_TITLE message:sweepMessageString preferredStyle:UIAlertControllerStyleAlert];
        
        UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self enablePaymentButtons];
        }];
        
        UIAlertAction *sendAction = [UIAlertAction actionWithTitle:BC_STRING_SEND style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            
            amountInSatoshi = maxAmount;
            // Display to the user the max amount
            [self doCurrencyConversion];
            
            if (![self isAmountAboveDustThreshold:maxAmount]) {
                [self enablePaymentButtons];
                return;
            }
            
            // Actually do the sweep and confirm
            [self getMaxFeeThenConfirm:YES];
        
        }];
        
        [alert addAction:cancelAction];
        [alert addAction:sendAction];
        
        [self.view.window.rootViewController presentViewController:alert animated:YES completion:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    });
}

- (void)showSummary
{
    [self hideKeyboard];
    
    // Timeout so the keyboard is fully dismised - otherwise the second password modal keyboard shows the send screen kebyoard accessory
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [app showModalWithContent:self.confirmPaymentView closeType:ModalCloseTypeBack headerText:BC_STRING_CONFIRM_PAYMENT onDismiss:^{
            [self enablePaymentButtons];
        } onResume:nil];
        
        [UIView animateWithDuration:0.3f animations:^{
            
            UIButton *paymentButton = self.confirmPaymentView.reallyDoPaymentButton;
            self.confirmPaymentView.reallyDoPaymentButton.frame = CGRectMake(0, self.view.frame.size.height + DEFAULT_FOOTER_HEIGHT - paymentButton.frame.size.height, paymentButton.frame.size.width, paymentButton.frame.size.height);
        }];

        uint64_t amountTotal = amountInSatoshi + self.feeFromTransactionProposal;
        
        NSString *fromAddressLabel = self.sendFromAddress ? [self labelForLegacyAddress:self.fromAddress] : [app.wallet getLabelForAccount:self.fromAccount activeOnly:YES];
        
        NSString *fromAddressString = self.sendFromAddress ? self.fromAddress : @"";
        
        if ([self.fromAddress isEqualToString:@""] && self.sendFromAddress) {
            fromAddressString = BC_STRING_ANY_ADDRESS;
        }
        
        // When a legacy wallet has no label, labelForLegacyAddress returns the address, so remove the string
        if ([fromAddressLabel isEqualToString:fromAddressString]) {
            fromAddressLabel = @"";
        }
        
        NSString *toAddressLabel = self.sendToAddress ? [self labelForLegacyAddress:self.toAddress] : [app.wallet getLabelForAccount:self.toAccount activeOnly:YES];
        NSString *toAddressString = self.sendToAddress ? self.toAddress : @"";
        
        // When a legacy wallet has no label, labelForLegacyAddress returns the address, so remove the string
        if ([toAddressLabel isEqualToString:toAddressString]) {
            toAddressLabel = @"";
        }
        
        self.confirmPaymentView.fromLabel.text = [NSString stringWithFormat:@"%@\n%@", fromAddressLabel, fromAddressString];
        self.confirmPaymentView.toLabel.text = [NSString stringWithFormat:@"%@\n%@", toAddressLabel, toAddressString];
        
        self.confirmPaymentView.fiatAmountLabel.text = [app formatMoney:amountInSatoshi localCurrency:TRUE];
        self.confirmPaymentView.btcAmountLabel.text = [app formatMoney:amountInSatoshi localCurrency:FALSE];
        
        self.confirmPaymentView.fiatFeeLabel.text = [app formatMoney:self.feeFromTransactionProposal localCurrency:TRUE];
        self.confirmPaymentView.btcFeeLabel.text = [app formatMoney:self.feeFromTransactionProposal localCurrency:FALSE];
        
        if (self.isSurgeOccurring) {
            self.confirmPaymentView.fiatFeeLabel.textColor = [UIColor redColor];
            self.confirmPaymentView.btcFeeLabel.textColor = [UIColor redColor];
        }
        
        self.confirmPaymentView.fiatTotalLabel.text = [app formatMoney:amountTotal localCurrency:TRUE];
        self.confirmPaymentView.btcTotalLabel.text = [app formatMoney:amountTotal localCurrency:FALSE];
    });
}

- (BOOL)isAmountAboveDustThreshold:(uint64_t)amount
{
    if (amount <= DUST_THRESHOLD) {
        [self alertUserForAmountBelowDustThreshold];
        return NO;
    } else {
        return YES;
    }
}

- (void)alertUserForAmountBelowDustThreshold
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:[[NSString alloc] initWithFormat:BC_STRING_MUST_BE_ABOVE_DUST_THRESHOLD, DUST_THRESHOLD] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    [self.view.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)alertUserForZeroSpendableAmount
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_NO_AVAILABLE_FUNDS message:BC_STRING_PLEASE_SELECT_DIFFERENT_ADDRESS preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    [self.view.window.rootViewController presentViewController:alert animated:YES completion:nil];
    [self enablePaymentButtons];
}

#pragma mark - UI Helpers

- (void)doCurrencyConversion
{
    // If the amount entered exceeds amount available, change the color of the amount text
    if (amountInSatoshi > availableAmount || amountInSatoshi > BTC_LIMIT_IN_SATOSHI) {
        [self highlightInvalidAmounts];
        [self disablePaymentButtons];
    }
    else {
        [self removeHighlightFromAmounts];
        [self enablePaymentButtons];

        [app.wallet changePaymentAmount:amountInSatoshi];
    }
    
    if ([btcAmountField isFirstResponder]) {
        fiatAmountField.text = [app formatAmount:amountInSatoshi localCurrency:YES];
    }
    else if ([fiatAmountField isFirstResponder]) {
        btcAmountField.text = [app formatAmount:amountInSatoshi localCurrency:NO];
    }
    else {
        
        fiatAmountField.text = [app formatAmount:amountInSatoshi localCurrency:YES];
        btcAmountField.text = [app formatAmount:amountInSatoshi localCurrency:NO];
    }
    
    [self updateFundsAvailable];
}

- (void)highlightInvalidAmounts
{
    btcAmountField.textColor = [UIColor redColor];
    fiatAmountField.textColor = [UIColor redColor];
}

- (void)removeHighlightFromAmounts
{
    btcAmountField.textColor = [UIColor blackColor];
    fiatAmountField.textColor = [UIColor blackColor];
}

- (void)disablePaymentButtons
{
    continuePaymentButton.enabled = NO;
    [continuePaymentButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [continuePaymentButton setBackgroundColor:COLOR_BUTTON_KEYPAD_GRAY];
    
    continuePaymentAccessoryButton.enabled = NO;
    [continuePaymentAccessoryButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [continuePaymentAccessoryButton setBackgroundColor:COLOR_BUTTON_KEYPAD_GRAY];
}

- (void)enablePaymentButtons
{
    continuePaymentButton.enabled = YES;
    [continuePaymentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [continuePaymentButton setBackgroundColor:COLOR_BUTTON_GREEN];
    
    [continuePaymentAccessoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    continuePaymentAccessoryButton.enabled = YES;
    [continuePaymentAccessoryButton setBackgroundColor:COLOR_BUTTON_GREEN];
}

- (void)setAmountFromUrlHandler:(NSString*)amountString withToAddress:(NSString*)addressString
{
    self.addressFromURLHandler = addressString;
    
    if ([app stringHasBitcoinValue:amountString]) {
        NSDecimalNumber *amountDecimalNumber = [NSDecimalNumber decimalNumberWithString:amountString];
        self.amountFromURLHandler = [[amountDecimalNumber decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:SATOSHI]] longLongValue];
    } else {
        self.amountFromURLHandler = 0;
    }
}

- (NSString *)labelForLegacyAddress:(NSString *)address
{
    if ([[app.wallet.addressBook objectForKey:address] length] > 0) {
        return [app.wallet.addressBook objectForKey:address];
        
    }
    else if ([app.wallet.allLegacyAddresses containsObject:address]) {
        NSString *label = [app.wallet labelForLegacyAddress:address];
        if (label && ![label isEqualToString:@""])
            return label;
    }
    
    return address;
}

- (void)hideKeyboard
{
    [btcAmountField resignFirstResponder];
    [fiatAmountField resignFirstResponder];
    [toField resignFirstResponder];
    [feeField resignFirstResponder];
    
    [self.view removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
}

- (BOOL)isKeyboardVisible
{
    if ([btcAmountField isFirstResponder] || [fiatAmountField isFirstResponder] || [toField isFirstResponder] || [feeField isFirstResponder]) {
        return YES;
    }
    
    return NO;
}

- (void)showErrorBeforeSending:(NSString *)error
{
    if ([self isKeyboardVisible]) {
        [self hideKeyboard];
        [app performSelector:@selector(standardNotifyAutoDismissingController:) withObject:error afterDelay:DELAY_KEYBOARD_DISMISSAL];
    } else {
        [app standardNotifyAutoDismissingController:error];
    }
}

- (void)showWarningForFee:(uint64_t)fee isHigherThanRecommendedRange:(BOOL)feeIsTooHigh
{
    NSString *message;
    uint64_t suggestedFee = 0;
    NSString *useSuggestedFee;
    NSString *keepUserInputFee;
    
    if (feeIsTooHigh) {
        message = [NSString stringWithFormat:BC_STRING_FEE_HIGHER_THAN_RECOMMENDED_ARGUMENT_SUGGESTED_ARGUMENT, [app formatMoney:fee localCurrency:NO], [app formatMoney:self.upperRecommendedLimit localCurrency:NO]];
        suggestedFee = self.upperRecommendedLimit;
        useSuggestedFee = BC_STRING_LOWER_FEE;
        keepUserInputFee = BC_STRING_KEEP_HIGHER_FEE;
    } else {
        message = [NSString stringWithFormat:BC_STRING_FEE_LOWER_THAN_RECOMMENDED_ARGUMENT_SUGGESTED_ARGUMENT, [app formatMoney:fee localCurrency:NO], [app formatMoney:self.lowerRecommendedLimit localCurrency:NO]];
        suggestedFee = self.lowerRecommendedLimit;
        useSuggestedFee = BC_STRING_INCREASE_FEE;
        keepUserInputFee = BC_STRING_KEEP_LOWER_FEE;
    }
    UIAlertController *alertForFeeOutsideRecommendedRange = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING_TITLE message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertForFeeOutsideRecommendedRange addAction:[UIAlertAction actionWithTitle:useSuggestedFee style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeForcedFee:suggestedFee afterEvaluation:YES];
    }]];
    [alertForFeeOutsideRecommendedRange addAction:[UIAlertAction actionWithTitle:keepUserInputFee style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeForcedFee:fee afterEvaluation:YES];
    }]];
    [alertForFeeOutsideRecommendedRange addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [app.tabViewController presentViewController:alertForFeeOutsideRecommendedRange animated:YES completion:nil];
}

- (void)alertUserForSpendingFromWatchOnlyAddress
{
    UIAlertController *alertForSpendingFromWatchOnly = [UIAlertController alertControllerWithTitle:BC_STRING_PRIVATE_KEY_NEEDED message:[NSString stringWithFormat:BC_STRING_PRIVATE_KEY_NEEDED_MESSAGE_ARGUMENT, self.fromAddress] preferredStyle:UIAlertControllerStyleAlert];
    [alertForSpendingFromWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self scanPrivateKeyToSendFromWatchOnlyAddress];
    }]];
    [alertForSpendingFromWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [app.tabViewController presentViewController:alertForSpendingFromWatchOnly animated:YES completion:nil];
}

- (void)scanPrivateKeyToSendFromWatchOnlyAddress
{
    if (![app getCaptureDeviceInput]) {
        return;
    }
    
    PrivateKeyReader *privateKeyScanner = [[PrivateKeyReader alloc] initWithSuccess:^(NSString *privateKeyString) {
        [app.wallet sendFromWatchOnlyAddress:self.fromAddress privateKey:privateKeyString];
    } error:^(NSString *error) {
        [app closeAllModals];
    } acceptPublicKeys:NO busyViewText:BC_STRING_LOADING_PROCESSING_KEY];
    
    [app.tabViewController presentViewController:privateKeyScanner animated:YES completion:nil];
}

- (void)changeToCustomFeeMode
{
    [self arrangeViewsToFeeMode];
    self.customFeeMode = YES;
}

- (void)changeToDefaultFeeMode
{    
    [self arrangeViewsToDefaultMode];
    self.customFeeMode = NO;
}

- (void)arrangeViewsToFeeMode
{
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        
        if ([[UIScreen mainScreen] bounds].size.height <= HEIGHT_IPHONE_4S) {
            toLabel.frame = CGRectMake(toLabel.frame.origin.x, 71, toLabel.frame.size.width, toLabel.frame.size.height);
            toField.frame = CGRectMake(toField.frame.origin.x, 67, toField.frame.size.width, toField.frame.size.height);
            addressBookButton.frame = CGRectMake(addressBookButton.frame.origin.x, 67, addressBookButton.frame.size.width, addressBookButton.frame.size.height);
            lineBelowToField.frame = CGRectMake(lineBelowToField.frame.origin.x, 100, lineBelowToField.frame.size.width, lineBelowToField.frame.size.height);
            
            bottomContainerView.frame = CGRectMake(bottomContainerView.frame.origin.x, 109, bottomContainerView.frame.size.width, bottomContainerView.frame.size.height);
            btcLabel.frame = CGRectMake(btcLabel.frame.origin.x, -3, btcLabel.frame.size.width, btcLabel.frame.size.height);
            btcAmountField.frame = CGRectMake(btcAmountField.frame.origin.x, -6, btcAmountField.frame.size.width, btcAmountField.frame.size.height);
            fiatLabel.frame = CGRectMake(fiatLabel.frame.origin.x, -3, fiatLabel.frame.size.width, fiatLabel.frame.size.height);
            fiatAmountField.frame = CGRectMake(fiatAmountField.frame.origin.x, -7, fiatAmountField.frame.size.width, fiatAmountField.frame.size.height);
            lineBelowAmountFields.frame = CGRectMake(lineBelowAmountFields.frame.origin.x, 22, lineBelowAmountFields.frame.size.width, lineBelowAmountFields.frame.size.height);
            
            feeField.frame = CGRectMake(feeField.frame.origin.x, 23, feeField.frame.size.width, feeField.frame.size.height);
            feeLabel.frame = CGRectMake(feeLabel.frame.origin.x, 26, feeLabel.frame.size.width, feeLabel.frame.size.height);
            lineBelowFeeField.frame = CGRectMake(lineBelowFeeField.frame.origin.x, 50, lineBelowFeeField.frame.size.width, lineBelowFeeField.frame.size.height);
        }
        
        feeField.hidden = NO;
        feeLabel.hidden = NO;
        lineBelowFeeField.hidden = NO;
    }];
    
    [feeField becomeFirstResponder];
}

- (void)arrangeViewsToDefaultMode
{
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        
        if ([[UIScreen mainScreen] bounds].size.height <= HEIGHT_IPHONE_4S) {
            toLabel.frame = CGRectMake(toLabel.frame.origin.x, 76, toLabel.frame.size.width, toLabel.frame.size.height);
            toField.frame = CGRectMake(toField.frame.origin.x, 72, toField.frame.size.width, toField.frame.size.height);
            addressBookButton.frame = CGRectMake(addressBookButton.frame.origin.x, 72, addressBookButton.frame.size.width, addressBookButton.frame.size.height);
            lineBelowToField.frame = CGRectMake(lineBelowToField.frame.origin.x, 111, lineBelowToField.frame.size.width, lineBelowToField.frame.size.height);
            
            bottomContainerView.frame = CGRectMake(bottomContainerView.frame.origin.x, 119, bottomContainerView.frame.size.width, bottomContainerView.frame.size.height);
            btcLabel.frame = CGRectMake(btcLabel.frame.origin.x, 6, btcLabel.frame.size.width, btcLabel.frame.size.height);
            btcAmountField.frame = CGRectMake(btcAmountField.frame.origin.x, 3, btcAmountField.frame.size.width, btcAmountField.frame.size.height);
            fiatLabel.frame = CGRectMake(fiatLabel.frame.origin.x, 6, fiatLabel.frame.size.width, fiatLabel.frame.size.height);
            fiatAmountField.frame = CGRectMake(fiatAmountField.frame.origin.x, 2, fiatAmountField.frame.size.width, fiatAmountField.frame.size.height);
            lineBelowAmountFields.frame = CGRectMake(lineBelowAmountFields.frame.origin.x, 40, lineBelowAmountFields.frame.size.width, lineBelowAmountFields.frame.size.height);
            
            feeField.frame = CGRectMake(feeField.frame.origin.x, 54, feeField.frame.size.width, feeField.frame.size.height);
            feeLabel.frame = CGRectMake(feeLabel.frame.origin.x, 51, feeLabel.frame.size.width, feeLabel.frame.size.height);
            lineBelowFeeField.frame = CGRectMake(lineBelowFeeField.frame.origin.x, 88, lineBelowFeeField.frame.size.width, lineBelowFeeField.frame.size.height);
        }
        
        feeField.hidden = YES;
        feeLabel.hidden = YES;
        lineBelowFeeField.hidden = YES;
    }];
}

#pragma mark - Textfield Delegates

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == selectAddressTextField) {
        // If we only have one account and no legacy addresses -> can't change from address
        if (!([app.wallet hasAccount] && ![app.wallet hasLegacyAddresses]
              && [app.wallet getActiveAccountsCount] == 1)) {
            [self selectFromAddressClicked:textField];
        }
        return NO;  // Hide both keyboard and blinking cursor.
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.tapGesture == nil) {
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)];
        
        [self.view addGestureRecognizer:self.tapGesture];
    }
    
    if (textField == btcAmountField) {
        displayingLocalSymbolSend = NO;
    }
    else if (textField == fiatAmountField) {
        displayingLocalSymbolSend = YES;
    }
    
    [self doCurrencyConversion];
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == btcAmountField || textField == fiatAmountField || textField == feeField) {
        
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray  *points = [newString componentsSeparatedByString:@"."];
        NSArray  *commas = [newString componentsSeparatedByString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
        
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
        if (textField == btcAmountField || textField == feeField) {
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
        else if (textField == fiatAmountField) {
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
        
        // Convert input amount to internal value
        NSString *amountString = [newString stringByReplacingOccurrencesOfString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator] withString:@"."];
        
        if (textField == feeField) {
            if ([app.wallet parseBitcoinValue:amountString] + amountInSatoshi > availableAmount) {
                textField.textColor = [UIColor redColor];
                [self disablePaymentButtons];
            } else {
                textField.textColor = [UIColor blackColor];
                [self enablePaymentButtons];
            }
            return YES;
        }
        
        if (textField == fiatAmountField) {
            amountInSatoshi = app.latestResponse.symbol_local.conversion * [amountString doubleValue];
        }
        else if (textField == btcAmountField) {
            amountInSatoshi = [app.wallet parseBitcoinValue:amountString];
        }
        
        if (amountInSatoshi > BTC_LIMIT_IN_SATOSHI) {
            return NO;
        } else {
            [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
            return YES;
        }
        
    } else if (textField == toField) {
        self.sendToAddress = true;
        self.toAddress = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (self.toAddress && [app.wallet isBitcoinAddress:self.toAddress]) {
            [self didSelectToAddress:self.toAddress];
            return NO;
        }
        DLog(@"toAddress: %@", self.toAddress);
    }
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    [textField resignFirstResponder];
    
    return YES;
}

- (void)updateFundsAvailable
{
    [fundsAvailableButton setTitle:[NSString stringWithFormat:BC_STRING_USE_ALL_AMOUNT,
                                    [app formatMoney:availableAmount localCurrency:displayingLocalSymbolSend]]
                          forState:UIControlStateNormal];
}

# pragma mark - AddressBook delegate

- (void)didSelectFromAddress:(NSString *)address
{
    self.sendFromAddress = true;
    
    NSString *addressOrLabel;
    NSString *label = [app.wallet labelForLegacyAddress:address];
    if (label && ![label isEqualToString:@""]) {
        addressOrLabel = label;
    }
    else {
        addressOrLabel = address;
    }
    
    availableAmount = [app.wallet getLegacyAddressBalance:address];
    
    selectAddressTextField.text = addressOrLabel;
    self.fromAddress = address;
    DLog(@"fromAddress: %@", address);
    
    [app.wallet changePaymentFromAddress:address];
    
    [self updateFundsAvailable];
    
    [self doCurrencyConversion];
}

- (void)didSelectToAddress:(NSString *)address
{
    self.sendToAddress = true;
    
    toField.text = [self labelForLegacyAddress:address];
    self.toAddress = address;
    DLog(@"toAddress: %@", address);
    
    [app.wallet changePaymentToAddress:address];
    
    [self doCurrencyConversion];
}

- (void)didSelectFromAccount:(int)account
{
    self.sendFromAddress = false;
    
    availableAmount = [app.wallet getBalanceForAccount:account activeOnly:YES];
    
    selectAddressTextField.text = [app.wallet getLabelForAccount:account activeOnly:YES];
    self.fromAccount = account;
    DLog(@"fromAccount: %@", [app.wallet getLabelForAccount:account activeOnly:YES]);
    
    [app.wallet changePaymentFromAccount:account];
    
    [self updateFundsAvailable];
    
    [self doCurrencyConversion];
}

- (void)didSelectToAccount:(int)account
{
    self.sendToAddress = false;
    
    toField.text = [app.wallet getLabelForAccount:account activeOnly:YES];
    self.toAccount = account;
    self.toAddress = @"";
    DLog(@"toAccount: %@", [app.wallet getLabelForAccount:account activeOnly:YES]);
    
    [app.wallet changePaymentToAccount:account];
    
    [self doCurrencyConversion];
}

#pragma mark - Fee Calculation

- (uint64_t)suggestedFee
{
    if (self.recommendedFees) {
        return (uint64_t)[self.recommendedFees[DICTIONARY_KEY_FEE_ESTIMATE][1][DICTIONARY_KEY_FEE] longLongValue];
    } else {
        return 0;
    }
}

- (void)getTransactionFeeWithSuccess:(void (^)())success error:(void (^)())error advanced:(BOOL)isAdvanced
{
    self.getTransactionFeeSuccess = success;
    
    [app.wallet getTransactionFee:isAdvanced];
}

- (void)didCheckForOverSpending:(NSNumber *)amount fee:(NSNumber *)fee
{
    self.feeFromTransactionProposal = [fee longLongValue];
    uint64_t maxAmount = [amount longLongValue];
    self.maxSendableAmount = maxAmount;
    
    if (maxAmount == 0) {
        [self alertUserForZeroSpendableAmount];
        return;
    }
    
    if (amountInSatoshi > maxAmount) {
        [self showSweepConfirmationScreenWithMaxAmount:maxAmount];
    } else {
        // Underspending - regular transaction
        __weak SendViewController *weakSelf = self;
        
        [self getTransactionFeeWithSuccess:^{
            [weakSelf showSummary];
        } error:nil advanced:self.customFeeMode];
    }
}

- (void)didGetMaxFee:(NSNumber *)fee amount:(NSNumber *)amount willConfirm:(BOOL)willConfirm
{
    self.feeFromTransactionProposal = [fee longLongValue];
    uint64_t maxAmount = [amount longLongValue];
    self.maxSendableAmount = maxAmount;
    
    DLog(@"SendViewController: got max fee of %lld", [fee longLongValue]);
    amountInSatoshi = maxAmount;
    [self doCurrencyConversion];
    
    if (maxAmount == 0) {
        [self alertUserForZeroSpendableAmount];
        return;
    }
    
    if (willConfirm) {
        [self showSummary];
    }
}

- (void)didGetFee:(NSNumber *)fee
{
    self.feeFromTransactionProposal = [fee longLongValue];
    self.recommendedForcedFee = [fee longLongValue];
    
    if (self.getTransactionFeeSuccess) {
        self.getTransactionFeeSuccess();
    }
}

- (void)checkMaxFee
{
    [app.wallet checkIfOverspending];
}

- (void)getMaxFeeThenConfirm:(BOOL)willConfirm
{
    [app.wallet sweepPaymentThenConfirm:willConfirm];
}

- (void)changeForcedFee:(uint64_t)absoluteFee afterEvaluation:(BOOL)afterEvaluation
{
    [app.wallet setForcedTransactionFee:absoluteFee afterEvaluation:(BOOL)afterEvaluation];
}

- (void)didChangeForcedFee:(NSNumber *)fee bounds:(NSArray *)bounds afterEvaluation:(BOOL)afterEvaluation
{
    self.feeFromTransactionProposal = [fee longLongValue];
    feeField.text = [app formatAmount:self.feeFromTransactionProposal localCurrency:FALSE];
    
    if (afterEvaluation) {
        [self checkMaxFee];
        return;
    }
    
    if ([self evaluateFee:[fee longLongValue] absoluteFeeBounds:bounds]) {
        uint64_t amountTotal = amountInSatoshi + self.feeFromTransactionProposal;
        
        self.confirmPaymentView.fiatFeeLabel.text = [app formatMoney:self.feeFromTransactionProposal localCurrency:TRUE];
        self.confirmPaymentView.btcFeeLabel.text = [app formatMoney:self.feeFromTransactionProposal localCurrency:FALSE];
        
        self.confirmPaymentView.fiatTotalLabel.text = [app formatMoney:amountTotal localCurrency:TRUE];
        self.confirmPaymentView.btcTotalLabel.text = [app formatMoney:amountTotal localCurrency:FALSE];
        
        [self checkMaxFee];
    }
}

- (BOOL)evaluateFee:(uint64_t)fee absoluteFeeBounds:(NSArray *)bounds
{
    BOOL isWithinRange = YES;
    
    self.upperRecommendedLimit = [[bounds firstObject] longLongValue];
    self.lowerRecommendedLimit = [[bounds lastObject] longLongValue];
    
    if (fee > self.upperRecommendedLimit) {
        isWithinRange = NO;
        [self showWarningForFee:fee isHigherThanRecommendedRange:YES];
    } else if (fee < self.lowerRecommendedLimit) {
        isWithinRange = NO;
        [self showWarningForFee:fee isHigherThanRecommendedRange:NO];
    }
    
    return isWithinRange;
}

#pragma mark - Actions

- (IBAction)selectFromAddressClicked:(id)sender
{
    BCAddressSelectionView *addressSelectionView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet showOwnAddresses:YES];
    addressSelectionView.delegate = self;
    
    [app showModalWithContent:addressSelectionView closeType:ModalCloseTypeBack showHeader:YES headerText:BC_STRING_SEND_FROM onDismiss:nil onResume:nil];
}

- (IBAction)addressBookClicked:(id)sender
{
    BCAddressSelectionView *addressSelectionView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet showOwnAddresses:NO];
    addressSelectionView.delegate = self;
    
    [app showModalWithContent:addressSelectionView closeType:ModalCloseTypeBack showHeader:YES headerText:BC_STRING_SEND_TO onDismiss:nil onResume:nil];
}

- (BOOL)startReadingQRCode
{
    AVCaptureDeviceInput *input = [app getCaptureDeviceInput];
    
    if (!input) {
        return NO;
    }
    
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CGRect frame = CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height + DEFAULT_FOOTER_HEIGHT);
    
    [videoPreviewLayer setFrame:frame];
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view.layer addSublayer:videoPreviewLayer];
    
    [app showModalWithContent:view closeType:ModalCloseTypeClose headerText:BC_STRING_SCAN_QR_CODE onDismiss:nil onResume:nil];
    
    [captureSession startRunning];
    
    return YES;
}

- (void)stopReadingQRCode
{
    [captureSession stopRunning];
    captureSession = nil;
    
    [videoPreviewLayer removeFromSuperlayer];
    
    [app closeModalWithTransition:kCATransitionFade];
    
    // Go to the send scren if we are not already on it
    [app showSendCoins];
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection
{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects firstObject];
        
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            [self performSelectorOnMainThread:@selector(stopReadingQRCode) withObject:nil waitUntilDone:NO];
            
            // do something useful with results
            dispatch_sync(dispatch_get_main_queue(), ^{
                NSDictionary *dict = [app parseURI:[metadataObj stringValue]];
                
                NSString *address = [dict objectForKey:@"address"];
                
                if (address == nil || ![app.wallet isBitcoinAddress:address]) {
                    [app standardNotify:[NSString stringWithFormat:BC_STRING_INVALID_ADDRESS_ARGUMENT, address]];
                    return;
                }
                
                toField.text = [self labelForLegacyAddress:address];
                self.toAddress = address;
                self.sendToAddress = true;
                DLog(@"toAddress: %@", self.toAddress);
                [self didSelectToAddress:self.toAddress];
                
                NSString *amountStringFromDictionary = [dict objectForKey:DICTIONARY_KEY_AMOUNT];
                if ([app stringHasBitcoinValue:amountStringFromDictionary]) {
                    if (app.latestResponse.symbol_btc) {
                        NSDecimalNumber *amountDecimalNumber = [NSDecimalNumber decimalNumberWithString:amountStringFromDictionary];
                        amountInSatoshi = [[amountDecimalNumber decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:SATOSHI]] longLongValue];
                    } else {
                        amountInSatoshi = 0.0;
                    }
                } else {
                    [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
                    return;
                }
                
                // If the amount is empty, open the amount field
                if (amountInSatoshi == 0) {
                    btcAmountField.text = nil;
                    fiatAmountField.text = nil;
                    [fiatAmountField becomeFirstResponder];
                }
                
                [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
            });
        }
    }
}

- (IBAction)QRCodebuttonClicked:(id)sender
{
    [self startReadingQRCode];
}

- (IBAction)closeKeyboardClicked:(id)sender
{
    [btcAmountField resignFirstResponder];
    [fiatAmountField resignFirstResponder];
    [toField resignFirstResponder];
    [feeField resignFirstResponder];
}

- (IBAction)labelAddressClicked:(id)sender
{
    [app.wallet addToAddressBook:toField.text label:labelAddressTextField.text];
    
    [app closeModalWithTransition:kCATransitionFade];
    labelAddressTextField.text = @"";
    
    // Complete payment
    [self showSummary];
}

- (IBAction)useAllClicked:(id)sender
{
    [btcAmountField resignFirstResponder];
    [fiatAmountField resignFirstResponder];
    
    [self getMaxFeeThenConfirm:NO];
}

- (IBAction)customizeFeeClicked:(UIButton *)sender
{
    [app closeModalWithTransition:kCATransitionFade];
    
    [self changeToCustomFeeMode];
    
    feeField.text = [app formatAmount:self.feeFromTransactionProposal localCurrency:NO];
}

- (IBAction)sendPaymentClicked:(id)sender
{
    if (![app checkInternetConnection]) {
        return;
    };
    
    if ([self.toAddress length] == 0) {
        self.toAddress = toField.text;
        DLog(@"toAddress: %@", self.toAddress);
    }
    
    if ([self.toAddress length] == 0) {
        [self showErrorBeforeSending:BC_STRING_YOU_MUST_ENTER_DESTINATION_ADDRESS];
        return;
    }
    
    if (self.sendToAddress && ![app.wallet isBitcoinAddress:self.toAddress]) {
        [self showErrorBeforeSending:BC_STRING_INVALID_TO_BITCOIN_ADDRESS];
        return;
    }
    
    if (!self.sendFromAddress && !self.sendToAddress && self.fromAccount == self.toAccount) {
        [self showErrorBeforeSending:BC_STRING_FROM_TO_DIFFERENT];
        return;
    }
    
    if (self.sendFromAddress && self.sendToAddress && [self.fromAddress isEqualToString:self.toAddress]) {
        [self showErrorBeforeSending:BC_STRING_FROM_TO_ADDRESS_DIFFERENT];
        return;
    }
    
    uint64_t value = amountInSatoshi;
    NSString *amountString = [btcAmountField.text stringByReplacingOccurrencesOfString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator] withString:@"."];
    if (value <= 0 || [amountString doubleValue] <= 0) {
        [self showErrorBeforeSending:BC_STRING_INVALID_SEND_VALUE];
        return;
    }
    
    if (![self isAmountAboveDustThreshold:value]) {
        return;
    }
    
    [self hideKeyboard];
    
    [self disablePaymentButtons];
    
    if (feeField.hidden) {
        [self checkMaxFee];
    } else {
        [self changeForcedFee:[app.wallet parseBitcoinValue:feeField.text] afterEvaluation:NO];
    }
    
    //    if ([[app.wallet.addressBook objectForKey:self.toAddress] length] == 0 && ![app.wallet.allLegacyAddresses containsObject:self.toAddress]) {
    //        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_ADD_TO_ADDRESS_BOOK
    //                                                        message:[NSString stringWithFormat:BC_STRING_ASK_TO_ADD_TO_ADDRESS_BOOK, self.toAddress]
    //                                                       delegate:nil
    //                                              cancelButtonTitle:BC_STRING_NO
    //                                              otherButtonTitles:BC_STRING_YES, nil];
    //
    //        alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
    //            // do nothing & proceed
    //            if (buttonIndex == 0) {
    //                [self confirmPayment];
    //            }
    //            // let user save address in addressbook
    //            else if (buttonIndex == 1) {
    //                labelAddressLabel.text = toField.text;
    //
    //                [app showModal:labelAddressView isClosable:TRUE];
    //
    //                [labelAddressTextField becomeFirstResponder];
    //            }
    //        };
    //        
    //        [alert show];
    //    } else {
    //        [self confirmPayment];
    //    }
}

@end

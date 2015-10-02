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

@interface SendViewController ()
@property (nonatomic) uint64_t feeFromTransactionProposal;
@property (nonatomic) uint64_t amountFromURLHandler;
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
    
    [toField setReturnKeyType:UIReturnKeyDone];
    
    [self reload];
}

- (void)resetPayment
{
    [app.wallet createNewPayment];
    [app.wallet changePaymentFromAddress:@""];
}

- (void)resetFromAddress
{
    self.fromAddress = @"";
    if ([app.wallet hasAccount]) {
        // Default setting: send from default account
        self.sendFromAddress = false;
        int defaultAccountIndex = [app.wallet getDefaultAccountIndex];
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
}

- (void)reload
{
    if (![app.wallet isInitialized]) {
        DLog(@"SendViewController: Wallet not initialized");
        return;
    }
    
    if (!app.latestResponse) {
        DLog(@"SendViewController: No latest response");
        return;
    }
    
    [self clearToAddressAndAmountFields];
    
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
}

- (void)hideSelectFromAndToButtonsIfAppropriate
{
    // If we only have one account and no legacy addresses -> can't change from address
    if ([app.wallet hasAccount] && ![app.wallet hasLegacyAddresses]
        && [app.wallet getAccountsCount] == 1) {
        
        [selectFromButton setHidden:YES];
        
        if ([app.wallet addressBook].count == 0) {
            [addressBookButton setHidden:YES];
        } else {
            [addressBookButton setHidden:NO];
        }
    }
    else {
        [selectFromButton setHidden:NO];
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
        selectAddressTextField.text = [app.wallet getLabelForAccount:self.fromAccount];
        availableAmount = [app.wallet getBalanceForAccount:self.fromAccount];
    }
}

- (void)reloadToField
{
    if (self.sendToAddress) {
        toField.text = [self labelForLegacyAddress:self.toAddress];
        if ([app.wallet isValidAddress:toField.text]) {
            [self didSelectToAddress:self.toAddress];
        } else {
            toField.text = @"";
            self.toAddress = @"";
        }
    }
    else {
        toField.text = [app.wallet getLabelForAccount:self.toAccount];
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
        [app playBeepSound];
        
        [app standardNotify:BC_STRING_PAYMENT_SENT title:BC_STRING_SUCCESS delegate:nil];
        
        [sendProgressActivityIndicator stopAnimating];
        
        [self enablePaymentButtons];
        
        // Fields are automatically reset by reload after a successful transaction
        
        // Close transaction modal, go to transactions view, scroll to top and animate new transaction
        [app closeModalWithTransition:kCATransitionFade];
        [app.transactionsViewController animateNextCellAfterReload];
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [app transactionsClicked:nil];
        });
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [app.transactionsViewController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
            [app.wallet loading_start_get_history];
        });
    };
    
    listener.on_error = ^(NSString* error) {
        if (error && error.length != 0) {
            [app standardNotify:error];
        }
        
        [sendProgressActivityIndicator stopAnimating];
        
        [self enablePaymentButtons];
        
        [app closeModalWithTransition:kCATransitionFade];
    };
    
    [self dismissKeyboard];
    
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
    
    [app.wallet sendPaymentWithListener:listener];
}

- (uint64_t)getInputAmountInSatoshi
{
    NSString *amountString = [btcAmountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    
    if (displayingLocalSymbol) {
        return app.latestResponse.symbol_local.conversion * [amountString doubleValue];
    } else {
        return [app.wallet parseBitcoinValue:amountString];
    }
}

- (void)showSweepConfirmationScreenWithMaxAmount:(uint64_t)maxAmount
{
    [self dismissKeyboard];
    
    // Timeout so the keyboard is fully dismised - otherwise the second password modal keyboard shows the send screen kebyoard accessory
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
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
            // Actually do the sweep and confirm
            [self getMaxFeeWhileConfirming:YES];
        }];
        
        [alert addAction:cancelAction];
        [alert addAction:sendAction];
        
        [self.view.window.rootViewController presentViewController:alert animated:YES completion:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    });
}

- (void)showSummary
{
    [self dismissKeyboard];
    
    // Timeout so the keyboard is fully dismised - otherwise the second password modal keyboard shows the send screen kebyoard accessory
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [app showModalWithContent:self.confirmPaymentView closeType:ModalCloseTypeBack headerText:BC_STRING_CONFIRM_PAYMENT onDismiss:^{
            [self enablePaymentButtons];
        } onResume:nil];
        
        [UIView animateWithDuration:0.3f animations:^{
            
            UIButton *paymentButton = self.confirmPaymentView.reallyDoPaymentButton;
            self.confirmPaymentView.reallyDoPaymentButton.frame = CGRectMake(0, self.view.frame.size.height + DEFAULT_FOOTER_HEIGHT - paymentButton.frame.size.height, paymentButton.frame.size.width, paymentButton.frame.size.height);
            NSLog(@"ANIMATING %@", NSStringFromCGRect(self.confirmPaymentView.reallyDoPaymentButton.frame));
        }];

        uint64_t amountTotal = amountInSatoshi + self.feeFromTransactionProposal;
        
        NSString *fromAddressLabel = self.sendFromAddress ? [self labelForLegacyAddress:self.fromAddress] : [app.wallet getLabelForAccount:self.fromAccount];
        NSString *fromAddressString = self.sendFromAddress ? self.fromAddress : [app.wallet getReceiveAddressForAccount:self.fromAccount];
        
        if ([self.fromAddress isEqualToString:@""]) {
            fromAddressString = BC_STRING_ANY_ADDRESS;
        }
        
        // When a legacy wallet has no label, labelForLegacyAddress returns the address, so remove the string
        if ([fromAddressLabel isEqualToString:fromAddressString]) {
            fromAddressLabel = @"";
        }
        
        NSString *toAddressLabel = self.sendToAddress ? [self labelForLegacyAddress:self.toAddress] : [app.wallet getLabelForAccount:self.toAccount];
        NSString *toAddressString = self.sendToAddress ? self.toAddress : [app.wallet getReceiveAddressForAccount:self.toAccount];
        
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
        
        self.confirmPaymentView.fiatTotalLabel.text = [app formatMoney:amountTotal localCurrency:TRUE];
        self.confirmPaymentView.btcTotalLabel.text = [app formatMoney:amountTotal localCurrency:FALSE];
    });
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
    continuePaymentAccessoryButton.enabled = NO;
    [continuePaymentButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
    [continuePaymentAccessoryButton setTitleColor:[UIColor grayColor] forState:UIControlStateNormal];
}

- (void)enablePaymentButtons
{
    continuePaymentButton.enabled = YES;
    continuePaymentAccessoryButton.enabled = YES;
    [continuePaymentButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [continuePaymentAccessoryButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
}

- (void)setAmountFromUrlHandler:(NSString*)amountString withToAddress:(NSString*)addressString
{
    self.addressFromURLHandler = addressString;
    
    NSDecimalNumber *amountDecimalNumber = [NSDecimalNumber decimalNumberWithString:amountString];
    self.amountFromURLHandler = [[amountDecimalNumber decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:SATOSHI]] longLongValue];
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

- (void)dismissKeyboard
{
    [btcAmountField resignFirstResponder];
    [fiatAmountField resignFirstResponder];
    [toField resignFirstResponder];
    
    [self.view removeGestureRecognizer:self.tapGesture];
    self.tapGesture = nil;
}

#pragma mark - Textfield Delegates

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (textField == selectAddressTextField) {
        // If we only have one account and no legacy addresses -> can't change from address
        if (!([app.wallet hasAccount] && ![app.wallet hasLegacyAddresses]
              && [app.wallet getAccountsCount] == 1)) {
            [self selectFromAddressClicked:textField];
        }
        return NO;  // Hide both keyboard and blinking cursor.
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    if (self.tapGesture == nil) {
        self.tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(dismissKeyboard)];
        
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
    if (textField == btcAmountField || textField == fiatAmountField) {
        
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray  *points = [newString componentsSeparatedByString:@"."];
        NSArray  *commas = [newString componentsSeparatedByString:@","];
        
        // Only one comma or point in input field allowed
        if ([points count] > 2 || [commas count] > 2)
            return NO;
        
        // Only 1 leading zero
        if (points.count == 1 || commas.count == 1) {
            if (range.location == 1 && ![string isEqualToString:@"."] && ![string isEqualToString:@","] && [textField.text isEqualToString:@"0"]) {
                return NO;
            }
        }
        
        // When entering amount in BTC, max 8 decimal places
        if (textField == btcAmountField) {
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
        else {
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
        NSString *amountString = [newString stringByReplacingOccurrencesOfString:@"," withString:@"."];
        if (textField == fiatAmountField) {
            amountInSatoshi = app.latestResponse.symbol_local.conversion * [amountString doubleValue];
        }
        else {
            amountInSatoshi = [app.wallet parseBitcoinValue:amountString];
        }
        
        [self performSelector:@selector(doCurrencyConversion) withObject:nil afterDelay:0.1f];
        
        return YES;
    } else if (textField == toField) {
        self.sendToAddress = true;
        self.toAddress = [textField.text stringByReplacingCharactersInRange:range withString:string];
        if (self.toAddress && [app.wallet isValidAddress:self.toAddress]) {
            [self didSelectToAddress:self.toAddress];
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
}

- (void)didSelectToAddress:(NSString *)address
{
    self.sendToAddress = true;
    
    toField.text = [self labelForLegacyAddress:address];
    self.toAddress = address;
    DLog(@"toAddress: %@", address);
    
    [app.wallet changePaymentToAddress:address];
}

- (void)didSelectFromAccount:(int)account
{
    self.sendFromAddress = false;
    
    availableAmount = [app.wallet getBalanceForAccount:account];
    
    selectAddressTextField.text = [app.wallet getLabelForAccount:account];
    self.fromAccount = account;
    DLog(@"fromAccount: %@", [app.wallet getLabelForAccount:account]);
    
    [app.wallet changePaymentFromAccount:account];
    
    [self updateFundsAvailable];
}

- (void)didSelectToAccount:(int)account
{
    self.sendToAddress = false;
    
    toField.text = [app.wallet getLabelForAccount:account];
    self.toAccount = account;
    self.toAddress = @"";
    DLog(@"toAccount: %@", [app.wallet getLabelForAccount:account]);
    
    [app.wallet changePaymentToAccount:account];
}

#pragma mark - Fee Calculation

- (void)alertUserForZeroSpendableAmount
{
    [app standardNotify:BC_STRING_NO_AVAILABLE_FUNDS];
    [self enablePaymentButtons];
}

- (void)addObserverForCheckingForOverspending
{
    __block id notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_CHECK_MAX_AMOUNT object:nil queue:nil usingBlock:^(NSNotification * notification) {
        [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver name:NOTIFICATION_KEY_CHECK_MAX_AMOUNT object:nil];
        if ([notification.userInfo count] != 0) {
            self.feeFromTransactionProposal = [notification.userInfo[DICTIONARY_KEY_FEE] longLongValue];
            uint64_t maxAmount = [notification.userInfo[DICTIONARY_KEY_AMOUNT] longLongValue];
            
            if (maxAmount == 0) {
                [self alertUserForZeroSpendableAmount];
                return;
            }
            
            if (amountInSatoshi > maxAmount) {
                [self showSweepConfirmationScreenWithMaxAmount:maxAmount];
            } else {
                // Underspending - regular transaction
                [self getFeeFromCurrentPayment];
            }
        }
    }];
}

- (void)addObserverForMaxFeeWhileConfirming:(BOOL)isConfirming
{
    __block id notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_UPDATE_FEE object:nil queue:nil usingBlock:^(NSNotification * notification) {
        [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver name:NOTIFICATION_KEY_UPDATE_FEE object:nil];
        if ([notification.userInfo count] != 0) {
            
            self.feeFromTransactionProposal = [notification.userInfo[DICTIONARY_KEY_FEE] longLongValue];
            uint64_t maxAmount = [notification.userInfo[DICTIONARY_KEY_AMOUNT] longLongValue];
            
            DLog(@"SendViewController: got max fee of %lld", [notification.userInfo[DICTIONARY_KEY_FEE] longLongValue]);
            amountInSatoshi = maxAmount;
            [self doCurrencyConversion];
            
            if (maxAmount == 0) {
                [self alertUserForZeroSpendableAmount];
                return;
            }
            
            if (isConfirming) {
                [self getFeeFromCurrentPayment];
            }
        }
    }];
}

- (void)addObserverForFee
{
    __block id notificationObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_UPDATE_FEE object:nil queue:nil usingBlock:^(NSNotification * notification) {
        [[NSNotificationCenter defaultCenter] removeObserver:notificationObserver name:NOTIFICATION_KEY_UPDATE_FEE object:nil];
        
        if ([notification.userInfo count] != 0) {
            
            NSString *errorString = [notification.userInfo valueForKey:@"error"];
            
            if (errorString != nil) {
                [app standardNotify:errorString];
                return;
            }
            
            uint64_t newFee = [notification.userInfo[@"fee"] longLongValue];
            self.feeFromTransactionProposal = newFee;
            DLog(@"SendViewController: got fee of %lld", newFee);
            
            [self showSummary];
            
        } else {
            [self enablePaymentButtons];
        }
    }];
}

- (void)getFeeFromCurrentPayment
{
    [self addObserverForFee];
    
    [app.wallet getPaymentFee];
}

- (void)checkMaxFee
{
    [self addObserverForCheckingForOverspending];
    
    [app.wallet checkIfOverspending];
}

- (void)getMaxFeeWhileConfirming:(BOOL)isConfirming
{
    [self addObserverForMaxFeeWhileConfirming:isConfirming];
    
    [app.wallet sweepPayment];
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
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        // This should never happen - all devices we support (iOS 7+) have cameras
        DLog(@"QR code scanner problem: %@", [error localizedDescription]);
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
                
                if (address == nil || ![app.wallet isValidAddress:address]) {
                    [app standardNotify:BC_STRING_INVALID_ADDRESS];
                    return;
                }
                
                toField.text = [self labelForLegacyAddress:address];
                self.toAddress = address;
                self.sendToAddress = true;
                DLog(@"toAddress: %@", self.toAddress);
                [self didSelectToAddress:self.toAddress];
                
                NSString *amountStringFromDictionary = [dict objectForKey:DICTIONARY_KEY_AMOUNT];
                if (amountStringFromDictionary != nil) {
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
    [self getMaxFeeWhileConfirming:NO];
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
        [app standardNotify:BC_STRING_YOU_MUST_ENTER_DESTINATION_ADDRESS];
        return;
    }
    
    if (self.sendToAddress && ![app.wallet isValidAddress:self.toAddress]) {
        [app standardNotify:BC_STRING_INVALID_TO_BITCOIN_ADDRESS];
        return;
    }
    
    if (!self.sendFromAddress && !self.sendToAddress && self.fromAccount == self.toAccount) {
        [app standardNotify:BC_STRING_FROM_TO_ACCOUNT_DIFFERENT];
        return;
    }
    
    if (self.sendFromAddress && self.sendToAddress && [self.fromAddress isEqualToString:self.toAddress]) {
        [app standardNotify:BC_STRING_FROM_TO_ADDRESS_DIFFERENT];
        return;
    }
    
    uint64_t value = amountInSatoshi;
    NSString *amountString = [btcAmountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
    if (value <= 0 || [amountString doubleValue] <= 0) {
        [app standardNotify:BC_STRING_INVALID_SEND_VALUE];
        return;
    }
    
    if (value <= DUST_THRESHOLD) {
        [app standardNotify:[[NSString alloc] initWithFormat:BC_STRING_MUST_BE_ABOVE_DUST_THRESHOLD, DUST_THRESHOLD]];
        return;
    }
    
    [self disablePaymentButtons];
    
    [self checkMaxFee];
    
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

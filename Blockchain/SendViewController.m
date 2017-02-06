//
//  SendViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SendViewController.h"
#import "Wallet.h"
#import "RootService.h"
#import "BCAddressSelectionView.h"
#import "TabViewController.h"
#import "UncaughtExceptionHandler.h"
#import "UITextField+Blocks.h"
#import "UIViewController+AutoDismiss.h"
#import "LocalizationConstants.h"
#import "TransactionsViewController.h"
#import "PrivateKeyReader.h"
#import "TransferAllFundsBuilder.h"

typedef enum {
    TransactionTypeRegular = 100,
    TransactionTypeSweep = 200,
    TransactionTypeSweepAndConfirm = 300,
} TransactionType;

@interface SendViewController () <UITextFieldDelegate, TransferAllFundsDelegate>

@property (nonatomic) TransactionType transactionType;

@property (nonatomic) uint64_t recommendedForcedFee;
@property (nonatomic) uint64_t maxSendableAmount;
@property (nonatomic) uint64_t feeFromTransactionProposal;
@property (nonatomic) uint64_t dust;
@property (nonatomic) uint64_t txSize;

@property (nonatomic) uint64_t amountFromURLHandler;

@property (nonatomic) uint64_t upperRecommendedLimit;
@property (nonatomic) uint64_t lowerRecommendedLimit;
@property (nonatomic) uint64_t estimatedTransactionSize;
@property (nonatomic) BOOL customFeeMode;

@property (nonatomic) BOOL isReloading;

@property (nonatomic, copy) void (^getTransactionFeeSuccess)();
@property (nonatomic, copy) void (^getDynamicFeeError)();

@property (nonatomic) TransferAllFundsBuilder *transferAllPaymentBuilder;

@end

@implementation SendViewController

AVCaptureSession *captureSession;
AVCaptureVideoPreviewLayer *videoPreviewLayer;

float containerOffset;

uint64_t amountInSatoshi = 0.0;
uint64_t availableAmount = 0.0;
uint64_t customFeeOriginalAvailableAmount = 0.0;

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
    
    btcAmountField.inputAccessoryView = amountKeyboardAccessoryView;
    fiatAmountField.inputAccessoryView = amountKeyboardAccessoryView;
    toField.inputAccessoryView = amountKeyboardAccessoryView;
    feeField.inputAccessoryView = amountKeyboardAccessoryView;
    
    self.confirmPaymentView.customizeFeeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    fundsAvailableButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    
    feeField.delegate = self;
    
    feeInformationButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    
    toField.placeholder = BC_STRING_ENTER_BITCOIN_ADDRESS_OR_SELECT;
    btcAmountField.placeholder = [NSString stringWithFormat:BTC_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    fiatAmountField.placeholder = [NSString stringWithFormat:FIAT_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];

    toField.clearButtonMode = UITextFieldViewModeWhileEditing;
    [toField setReturnKeyType:UIReturnKeyDone];
    
    [self reload];
}

- (void)resetPayment
{
    self.surgeIsOccurring = NO;
    self.dust = 0;
    
    [app.wallet createNewPayment];
    [self resetFromAddress];
    if (app.tabViewController.activeViewController == self) {
        [app closeModalWithTransition:kCATransitionPush];
    }
    
    self.transactionType = TransactionTypeRegular;
}

- (void)resetFromAddress
{
    self.fromAddress = @"";
    if ([app.wallet hasAccount]) {
        // Default setting: send from default account
        self.sendFromAddress = false;
        int defaultAccountIndex = [app.wallet getFilteredOrDefaultAccountIndex];
        self.fromAccount = defaultAccountIndex;
        if (self.isReloading) return; // didSelectFromAccount will be called in reloadAfterMultiAddressResponse
        [self didSelectFromAccount:self.fromAccount];
    }
    else {
        // Default setting: send from any address
        self.sendFromAddress = true;
        if (self.isReloading) return; // didSelectFromAddress will be called in reloadAfterMultiAddressResponse
        [self didSelectFromAddress:self.fromAddress];
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
    self.isReloading = YES;
    
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
    
    // Default: send to address
    self.sendToAddress = true;
    
    [self hideSelectFromAndToButtonsIfAppropriate];
    
    [self populateFieldsFromURLHandlerIfAvailable];
    
    [self reloadFromAndToFields];
    
    [self reloadSymbols];
    
    [self updateFundsAvailable];
    
    [self enablePaymentButtons];
    
    [self changeToDefaultFeeMode];
    
    [self.confirmPaymentView.reallyDoPaymentButton removeTarget:self action:nil forControlEvents:UIControlEventAllTouchEvents];
    [self.confirmPaymentView.reallyDoPaymentButton addTarget:self action:@selector(reallyDoPayment:) forControlEvents:UIControlEventTouchUpInside];
    
    self.confirmPaymentView.customizeFeeButton.hidden = NO;
    sendProgressCancelButton.hidden = YES;
    
    self.isSending = NO;
    self.isReloading = NO;
}

- (void)reloadAfterMultiAddressResponse
{
    [self hideSelectFromAndToButtonsIfAppropriate];
    
    [self reloadLocalAndBtcSymbolsFromLatestResponse];
    
    if (self.sendFromAddress) {
        [app.wallet changePaymentFromAddress:self.fromAddress isAdvanced:self.customFeeMode];
    } else {
        [app.wallet changePaymentFromAccount:self.fromAccount isAdvanced:self.customFeeMode];
    }
}

- (void)reloadSymbols
{
    [self reloadLocalAndBtcSymbolsFromLatestResponse];
    [self updateFundsAvailable];
}

- (void)hideSelectFromAndToButtonsIfAppropriate
{
    // If we only have one account and no legacy addresses -> can't change from address
    if ([app.wallet getActiveAccountsCount] + [[app.wallet activeLegacyAddresses] count] == 1) {
        
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
            availableAmount = [app.wallet getTotalBalanceForSpendableActiveLegacyAddresses];
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
        if ([app.wallet isBitcoinAddress:toField.text]) {
            [self selectToAddress:self.toAddress];
        } else {
            toField.text = @"";
            self.toAddress = @"";
        }
    }
    else {
        toField.text = [app.wallet getLabelForAccount:self.toAccount];
        [self selectToAccount:self.toAccount];
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
    if (self.sendFromAddress && [app.wallet isWatchOnlyLegacyAddress:self.fromAddress]) {
        
        [self alertUserForSpendingFromWatchOnlyAddress];
    
        return;
    } else {
        [self sendPaymentWithListener];
    }
}

- (void)getInfoForTransferAllFundsToDefaultAccount
{
    app.topViewControllerDelegate = nil;
    
    [app showBusyViewWithLoadingText:BC_STRING_TRANSFER_ALL_PREPARING_TRANSFER];
    
    [app.wallet getInfoForTransferAllFundsToAccount];
}

- (void)transferFundsToDefaultAccountFromAddress:(NSString *)address
{
    [self didSelectFromAddress:address];
    
    [self selectToAccount:[app.wallet getDefaultAccountIndex]];
    
    [app.wallet transferFundsToDefaultAccountFromAddress:address];
}

- (void)sendFromWatchOnlyAddress
{
    [self sendPaymentWithListener];
}

- (void)sendPaymentWithListener
{
    [self disablePaymentButtons];
    
    [sendProgressActivityIndicator startAnimating];
    
    sendProgressModalText.text = BC_STRING_SENDING_TRANSACTION;
    
    [app showModalWithContent:sendProgressModal closeType:ModalCloseTypeNone headerText:BC_STRING_SENDING_TRANSACTION];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
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
         
         listener.on_success = ^(NSString*secondPassword) {
             
             DLog(@"SendViewController: on_success");
             
             UIAlertController *paymentSentAlert = [UIAlertController alertControllerWithTitle:BC_STRING_SUCCESS message:BC_STRING_PAYMENT_SENT preferredStyle:UIAlertControllerStyleAlert];
             [paymentSentAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                 if (![[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_HIDE_APP_REVIEW_PROMPT]) {
                     
                     if ([app.wallet getAllTransactionsCount] < NUMBER_OF_TRANSACTIONS_REQUIRED_FOR_FOR_APP_STORE_REVIEW_PROMPT) {
                         return;
                     }
                     
                     id promptDate = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_APP_REVIEW_PROMPT_DATE];
                     
                     if (promptDate) {
                         NSTimeInterval secondsSincePrompt = [[NSDate date] timeIntervalSinceDate:promptDate];
                         NSTimeInterval secondsUntilPromptingAgain = TIME_INTERVAL_APP_STORE_REVIEW_PROMPT;
#ifdef ENABLE_DEBUG_MENU
                         id customTimeValue = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_APP_REVIEW_PROMPT_CUSTOM_TIMER];
                         if (customTimeValue) {
                             secondsUntilPromptingAgain = [customTimeValue doubleValue];
                         }
#endif
                         if (secondsSincePrompt < secondsUntilPromptingAgain) {
                             return;
                         }
                     }
                     
                     UIAlertController *appReviewAlert = [UIAlertController alertControllerWithTitle:BC_STRING_APP_REVIEW_PROMPT_TITLE message:BC_STRING_APP_REVIEW_PROMPT_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
                     [appReviewAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_YES_RATE_BLOCKCHAIN_WALLET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                         [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_KEY_HIDE_APP_REVIEW_PROMPT];
                         [app rateApp];
                     }]];
                     [appReviewAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_ASK_ME_LATER style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                         [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:USER_DEFAULTS_KEY_APP_REVIEW_PROMPT_DATE];
                     }]];
                     [appReviewAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_DONT_SHOW_AGAIN style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                         [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_KEY_HIDE_APP_REVIEW_PROMPT];
                     }]];
                     
                     [app.window.rootViewController presentViewController:appReviewAlert animated:YES completion:nil];
                 }
             }]];
             
             [app.window.rootViewController presentViewController:paymentSentAlert animated:YES completion:nil];
             
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
             
             [self reload];
         };
         
         listener.on_error = ^(NSString* error, NSString* secondPassword) {
             DLog(@"Send error: %@", error);
                          
             if ([error isEqualToString:ERROR_UNDEFINED]) {
                 [app standardNotify:BC_STRING_SEND_ERROR_NO_INTERNET_CONNECTION];
             } else if ([error isEqualToString:ERROR_FEE_TOO_LOW]) {
                 [app standardNotify:BC_STRING_SEND_ERROR_FEE_TOO_LOW];
             } else if ([error isEqualToString:ERROR_FAILED_NETWORK_REQUEST]) {
                 [app standardNotify:BC_STRING_REQUEST_FAILED_PLEASE_CHECK_INTERNET_CONNECTION];
             } else if (error && error.length != 0)  {
                 [app standardNotify:error];
             }
             
             [sendProgressActivityIndicator stopAnimating];
             
             [self enablePaymentButtons];
             
             [app closeModalWithTransition:kCATransitionFade];
             
             [self reload];
             
             [app.wallet getHistory];
         };
         
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
         
         [app.wallet sendPaymentWithListener:listener secondPassword:nil];
    });
}

- (void)transferAllFundsToDefaultAccount
{
    __weak SendViewController *weakSelf = self;
    
    self.transferAllPaymentBuilder.on_before_send = ^() {
        
        SendViewController *strongSelf = weakSelf;
        
        [weakSelf hideKeyboard];
        
        [weakSelf disablePaymentButtons];
        
        [strongSelf->sendProgressActivityIndicator startAnimating];
        
        if (weakSelf.transferAllPaymentBuilder.transferAllAddressesInitialCount - [weakSelf.transferAllPaymentBuilder.transferAllAddressesToTransfer count] <= weakSelf.transferAllPaymentBuilder.transferAllAddressesInitialCount) {
            strongSelf->sendProgressModalText.text = [NSString stringWithFormat:BC_STRING_TRANSFER_ALL_FROM_ADDRESS_ARGUMENT_ARGUMENT, weakSelf.transferAllPaymentBuilder.transferAllAddressesInitialCount - [weakSelf.transferAllPaymentBuilder.transferAllAddressesToTransfer count] + 1, weakSelf.transferAllPaymentBuilder.transferAllAddressesInitialCount];
        }
        
        [app showModalWithContent:strongSelf->sendProgressModal closeType:ModalCloseTypeNone headerText:BC_STRING_SENDING_TRANSACTION];
        
        [UIView animateWithDuration:0.3f animations:^{
            UIButton *cancelButton = strongSelf->sendProgressCancelButton;
            strongSelf->sendProgressCancelButton.frame = CGRectMake(0, self.view.frame.size.height + DEFAULT_FOOTER_HEIGHT - cancelButton.frame.size.height, cancelButton.frame.size.width, cancelButton.frame.size.height);
        }];
        
        weakSelf.isSending = YES;
    };
    
    self.transferAllPaymentBuilder.on_prepare_next_transfer = ^(NSArray *transferAllAddressesToTransfer) {
        weakSelf.fromAddress = transferAllAddressesToTransfer[0];
    };
    
    self.transferAllPaymentBuilder.on_success = ^(NSString *secondPassword) {
        
    };
    
    self.transferAllPaymentBuilder.on_error = ^(NSString *error, NSString *secondPassword) {
        
        SendViewController *strongSelf = weakSelf;

        [app closeAllModals];

        [strongSelf->sendProgressActivityIndicator stopAnimating];
        
        [weakSelf enablePaymentButtons];
        
        [weakSelf reload];
    };

    [self.transferAllPaymentBuilder transferAllFundsToAccountWithSecondPassword:nil];
}

- (void)didFinishTransferFunds:(NSString *)summary
{
    NSString *message = [self.transferAllPaymentBuilder.transferAllAddressesTransferred count] > 0 ? [NSString stringWithFormat:@"%@\n\n%@", summary, BC_STRING_PAYMENT_ASK_TO_ARCHIVE_TRANSFERRED_ADDRESSES] : summary;
    
    UIAlertController *alertForPaymentsSent = [UIAlertController alertControllerWithTitle:BC_STRING_PAYMENTS_SENT message:message preferredStyle:UIAlertControllerStyleAlert];
    
    if ([self.transferAllPaymentBuilder.transferAllAddressesTransferred count] > 0) {
        [alertForPaymentsSent addAction:[UIAlertAction actionWithTitle:BC_STRING_ARCHIVE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
            [self archiveTransferredAddresses];
        }]];
        [alertForPaymentsSent addAction:[UIAlertAction actionWithTitle:BC_STRING_NOT_NOW style:UIAlertActionStyleCancel handler:nil]];
    } else {
        [alertForPaymentsSent addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    }
    
    [app.tabViewController presentViewController:alertForPaymentsSent animated:YES completion:nil];
    
    [sendProgressActivityIndicator stopAnimating];
    
    [self enablePaymentButtons];
    
    // Fields are automatically reset by reload, called by MyWallet.wallet.getHistory() after a utx websocket message is received. However, we cannot rely on the websocket 100% of the time.
    [app.wallet performSelector:@selector(getHistoryIfNoTransactionMessage) withObject:nil afterDelay:DELAY_GET_HISTORY_BACKUP];
    
    // Close transaction modal, go to transactions view, scroll to top and animate new transaction
    [app closeAllModals];
    [app.transactionsViewController animateNextCellAfterReload];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [app transactionsClicked:nil];
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [app.transactionsViewController.tableView scrollRectToVisible:CGRectMake(0, 0, 1, 1) animated:NO];
    });
    
    [self reload];
}

- (void)sendDuringTransferAll:(NSString *)secondPassword
{
    [self.transferAllPaymentBuilder transferAllFundsToAccountWithSecondPassword:secondPassword];
}

- (void)didErrorDuringTransferAll:(NSString *)error secondPassword:(NSString *)secondPassword
{
    [app closeAllModals];
    [self reload];
    
    [self showErrorBeforeSending:error];
}

- (uint64_t)getInputAmountInSatoshi
{
    if (displayingLocalSymbol) {
        NSString *language = btcAmountField.textInputMode.primaryLanguage;
        NSLocale *locale = language ? [NSLocale localeWithLocaleIdentifier:language] : [NSLocale currentLocale];
        
        NSString *amountString = [btcAmountField.text stringByReplacingOccurrencesOfString:[locale objectForKey:NSLocaleDecimalSeparator] withString:@"."];
        if (![amountString containsString:@"."]) {
            amountString = [amountString stringByReplacingOccurrencesOfString:@"," withString:@"."];
        }
        if (![amountString containsString:@"."]) {
            amountString = [amountString stringByReplacingOccurrencesOfString:@"٫" withString:@"."];
        }
        return app.latestResponse.symbol_local.conversion * [amountString doubleValue];
    } else {
        return [app.wallet parseBitcoinValueFromTextField:btcAmountField];
    }
}

- (void)showSweepConfirmationScreenWithMaxAmount:(uint64_t)maxAmount
{
    [self hideKeyboard];
    
    // Timeout so the keyboard is fully dismised - otherwise the second password modal keyboard shows the send screen kebyoard accessory
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        self.maxSendableAmount = maxAmount;
        
        uint64_t spendableAmount = maxAmount + self.feeFromTransactionProposal;
        
        NSString *wantToSendAmountString = [NSNumberFormatter formatMoney:amountInSatoshi localCurrency:NO];
        NSString *spendableAmountString = [NSNumberFormatter formatMoney:spendableAmount localCurrency:NO];
        NSString *feeAmountString = [NSNumberFormatter formatMoney:self.feeFromTransactionProposal localCurrency:NO];
        
        NSString *canSendAmountString = [NSNumberFormatter formatMoney:maxAmount localCurrency:NO];
        
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
            self.transactionType = TransactionTypeSweepAndConfirm;
            
            if (self.customFeeMode) {
                [app.wallet sweepPaymentAdvancedThenConfirm:[app.wallet parseBitcoinValueFromTextField:feeField]];
            } else {
                [app.wallet sweepPaymentRegularThenConfirm];
            }
        
        }];
        
        [alert addAction:cancelAction];
        [alert addAction:sendAction];
        
        [self.view.window.rootViewController presentViewController:alert animated:YES completion:nil];
        
        [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    });
}

- (void)showSummary
{
    [self showSummaryWithCustomFromLabel:nil];
}

- (void)showSummaryWithCustomFromLabel:(NSString *)customFromLabel
{
    [self hideKeyboard];
    
    // Timeout so the keyboard is fully dismised - otherwise the second password modal keyboard shows the send screen kebyoard accessory
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        [app showModalWithContent:self.confirmPaymentView closeType:ModalCloseTypeBack headerText:BC_STRING_CONFIRM_PAYMENT onDismiss:^{
            [self enablePaymentButtons];
        } onResume:nil];
        
        if ([self transferAllMode]) {
            [app.modalView.backButton addTarget:self action:@selector(reload) forControlEvents:UIControlEventTouchUpInside];
        }
        
        [UIView animateWithDuration:0.3f animations:^{
            
            UIButton *paymentButton = self.confirmPaymentView.reallyDoPaymentButton;
            self.confirmPaymentView.reallyDoPaymentButton.frame = CGRectMake(0, self.view.frame.size.height + DEFAULT_FOOTER_HEIGHT - paymentButton.frame.size.height, paymentButton.frame.size.width, paymentButton.frame.size.height);
        }];
        
        uint64_t amountTotal = amountInSatoshi + self.feeFromTransactionProposal + self.dust;
        uint64_t feeTotal = self.dust + self.feeFromTransactionProposal;
        
        NSString *fromAddressLabel = self.sendFromAddress ? [self labelForLegacyAddress:self.fromAddress] : [app.wallet getLabelForAccount:self.fromAccount];
        
        NSString *fromAddressString = self.sendFromAddress ? self.fromAddress : @"";
        
        if ([self.fromAddress isEqualToString:@""] && self.sendFromAddress) {
            fromAddressString = BC_STRING_ANY_ADDRESS;
        }
        
        // When a legacy wallet has no label, labelForLegacyAddress returns the address, so remove the string
        if ([fromAddressLabel isEqualToString:fromAddressString]) {
            fromAddressLabel = @"";
        }
        
        if (customFromLabel) {
            fromAddressString = customFromLabel;
        }
        
        NSString *toAddressLabel = self.sendToAddress ? [self labelForLegacyAddress:self.toAddress] : [app.wallet getLabelForAccount:self.toAccount];
        NSString *toAddressString = self.sendToAddress ? self.toAddress : @"";
        
        // When a legacy wallet has no label, labelForLegacyAddress returns the address, so remove the string
        if ([toAddressLabel isEqualToString:toAddressString]) {
            toAddressLabel = @"";
        }
        
        self.confirmPaymentView.fromLabel.text = [NSString stringWithFormat:@"%@\n%@", fromAddressLabel, fromAddressString];
        self.confirmPaymentView.toLabel.text = [NSString stringWithFormat:@"%@\n%@", toAddressLabel, toAddressString];
        
        self.confirmPaymentView.fiatAmountLabel.text = [NSNumberFormatter formatMoney:amountInSatoshi localCurrency:TRUE];
        self.confirmPaymentView.btcAmountLabel.text = [NSNumberFormatter formatMoney:amountInSatoshi localCurrency:FALSE];
        
        self.confirmPaymentView.fiatFeeLabel.text = [NSNumberFormatter formatMoney:feeTotal localCurrency:TRUE];
        self.confirmPaymentView.btcFeeLabel.text = [NSNumberFormatter formatMoney:feeTotal localCurrency:FALSE];
        
        if (self.surgeIsOccurring || [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_SIMULATE_SURGE]) {
            self.confirmPaymentView.fiatFeeLabel.textColor = [UIColor redColor];
            self.confirmPaymentView.btcFeeLabel.textColor = [UIColor redColor];
        } else {
            self.confirmPaymentView.fiatFeeLabel.textColor = [UIColor darkGrayColor];
            self.confirmPaymentView.btcFeeLabel.textColor = [UIColor darkGrayColor];
        }
        
        self.confirmPaymentView.fiatTotalLabel.text = [NSNumberFormatter formatMoney:amountTotal localCurrency:TRUE];
        self.confirmPaymentView.btcTotalLabel.text = [NSNumberFormatter formatMoney:amountTotal localCurrency:FALSE];
        
        if (!self.customFeeMode) {
            NSDecimalNumber *last = [NSDecimalNumber decimalNumberWithDecimal:[[NSDecimalNumber numberWithDouble:[[app.wallet.currencySymbols objectForKey:DICTIONARY_KEY_USD][DICTIONARY_KEY_LAST] doubleValue]] decimalValue]];
            NSDecimalNumber *conversionToUSD = [[NSDecimalNumber decimalNumberWithDecimal:[[NSDecimalNumber numberWithDouble:SATOSHI] decimalValue]] decimalNumberByDividingBy:last];
            NSDecimalNumber *feeConvertedToUSD = [(NSDecimalNumber *)[NSDecimalNumber numberWithLongLong:feeTotal] decimalNumberByDividingBy:conversionToUSD];
            
            NSDecimalNumber *feeRatio = [[NSDecimalNumber decimalNumberWithDecimal:[[NSDecimalNumber numberWithLongLong:feeTotal] decimalValue] ] decimalNumberByDividingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithLongLong:amountTotal]];
            NSDecimalNumber *normalFeeRatio = [NSDecimalNumber decimalNumberWithDecimal:[ONE_PERCENT_DECIMAL decimalValue]];

            if ([feeConvertedToUSD compare:[NSDecimalNumber decimalNumberWithDecimal:[FIFTY_CENTS_DECIMAL decimalValue]]] == NSOrderedDescending && self.txSize > TX_SIZE_ONE_KILOBYTE && [feeRatio compare:normalFeeRatio] == NSOrderedDescending) {
                UIAlertController *highFeeAlert = [UIAlertController alertControllerWithTitle:BC_STRING_HIGH_FEE_WARNING_TITLE message:BC_STRING_HIGH_FEE_WARNING_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
                [highFeeAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
                [self.view.window.rootViewController presentViewController:highFeeAlert animated:YES completion:nil];
            }
        }
    });
}

- (void)alertUserForZeroSpendableAmount
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_NO_AVAILABLE_FUNDS message:BC_STRING_PLEASE_SELECT_DIFFERENT_ADDRESS preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    [self.view.window.rootViewController presentViewController:alert animated:YES completion:nil];
    [self enablePaymentButtons];
}

- (IBAction)sendProgressCancelButtonClicked:(UIButton *)sender
{
    sendProgressModalText.text = BC_STRING_CANCELLING;
    self.transferAllPaymentBuilder.userCancelledNext = YES;
    [self performSelector:@selector(cancelAndReloadIfTransferFails) withObject:nil afterDelay:10.0];
}

- (void)cancelAndReloadIfTransferFails
{
    if (self.isSending && [sendProgressModalText.text isEqualToString:BC_STRING_CANCELLING]) {
        [self reload];
        [app closeAllModals];
    }
}

#pragma mark - UI Helpers

- (void)doCurrencyConversion
{
    [self doCurrencyConversionAfterMultiAddress:NO];
}

- (void)doCurrencyConversionAfterMultiAddress
{
    [self doCurrencyConversionAfterMultiAddress:YES];
}

- (void)doCurrencyConversionAfterMultiAddress:(BOOL)afterMultiAddress
{
    // If the amount entered exceeds amount available, change the color of the amount text
    if (amountInSatoshi > availableAmount || amountInSatoshi > BTC_LIMIT_IN_SATOSHI) {
        [self highlightInvalidAmounts];
        [self disablePaymentButtons];
    }
    else {
        [self removeHighlightFromAmounts];
        [self enablePaymentButtons];
        if (!afterMultiAddress) {
            [app.wallet changePaymentAmount:amountInSatoshi];
        }
    }
    
    if ([btcAmountField isFirstResponder]) {
        fiatAmountField.text = [NSNumberFormatter formatAmount:amountInSatoshi localCurrency:YES];
    }
    else if ([fiatAmountField isFirstResponder]) {
        btcAmountField.text = [NSNumberFormatter formatAmount:amountInSatoshi localCurrency:NO];
    }
    else {
        
        fiatAmountField.text = [NSNumberFormatter formatAmount:amountInSatoshi localCurrency:YES];
        btcAmountField.text = [NSNumberFormatter formatAmount:amountInSatoshi localCurrency:NO];
    }
    
    if (self.customFeeMode) {
        uint64_t typedFee = [app.wallet parseBitcoinValueFromTextField:feeField];
        uint64_t spendableAmount = 0;
        if (typedFee < customFeeOriginalAvailableAmount) {
            spendableAmount = customFeeOriginalAvailableAmount - typedFee;
        }
        availableAmount = spendableAmount;
        
        if (typedFee + amountInSatoshi > customFeeOriginalAvailableAmount) {
            [self disablePaymentButtons];
            
            if ([feeField isFirstResponder]) {
                feeField.textColor = [UIColor redColor];
            } else {
                [self highlightInvalidAmounts];
            }
        } else {
            [self enablePaymentButtons];
            
            feeField.textColor = [UIColor blackColor];
            [self removeHighlightFromAmounts];
        }
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
    
    if ([NSNumberFormatter stringHasBitcoinValue:amountString]) {
        NSDecimalNumber *amountDecimalNumber = [NSDecimalNumber decimalNumberWithString:amountString];
        self.amountFromURLHandler = [[amountDecimalNumber decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:SATOSHI]] longLongValue];
    } else {
        self.amountFromURLHandler = 0;
    }
    
    _addressSource = DestinationAddressSourceURI;
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

- (void)hideKeyboardForced
{
    // When backgrounding the app quickly, the input accessory view can remain visible without a first responder, so force the keyboard to appear before dismissing it
    [fiatAmountField becomeFirstResponder];
    [self hideKeyboard];
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
        message = [NSString stringWithFormat:BC_STRING_FEE_HIGHER_THAN_RECOMMENDED_ARGUMENT_SUGGESTED_ARGUMENT, [NSNumberFormatter formatMoney:fee localCurrency:NO], [NSNumberFormatter formatMoney:self.upperRecommendedLimit localCurrency:NO]];
        suggestedFee = self.upperRecommendedLimit;
        useSuggestedFee = BC_STRING_LOWER_FEE;
        keepUserInputFee = BC_STRING_KEEP_HIGHER_FEE;
    } else {
        message = [NSString stringWithFormat:BC_STRING_FEE_LOWER_THAN_RECOMMENDED_ARGUMENT_SUGGESTED_ARGUMENT, [NSNumberFormatter formatMoney:fee localCurrency:NO], [NSNumberFormatter formatMoney:self.lowerRecommendedLimit localCurrency:NO]];
        suggestedFee = self.lowerRecommendedLimit;
        useSuggestedFee = BC_STRING_INCREASE_FEE;
        keepUserInputFee = BC_STRING_KEEP_LOWER_FEE;
    }
    UIAlertController *alertForFeeOutsideRecommendedRange = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING_TITLE message:message preferredStyle:UIAlertControllerStyleAlert];
    [alertForFeeOutsideRecommendedRange addAction:[UIAlertAction actionWithTitle:useSuggestedFee style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        feeField.text = [NSNumberFormatter formatAmount:suggestedFee localCurrency:NO];
        [self changeForcedFee:suggestedFee afterEvaluation:YES];
    }]];
    [alertForFeeOutsideRecommendedRange addAction:[UIAlertAction actionWithTitle:keepUserInputFee style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeForcedFee:fee afterEvaluation:YES];
    }]];
    [alertForFeeOutsideRecommendedRange addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        [self enablePaymentButtons];
    }]];
    
    [[NSNotificationCenter defaultCenter] addObserver:alertForFeeOutsideRecommendedRange selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    
    [app.tabViewController presentViewController:alertForFeeOutsideRecommendedRange animated:YES completion:nil];
}

- (void)showWarningForInsufficientFundsAndLowFee:(uint64_t)fee suggestedFee:(uint64_t)suggestedFee suggestedAmount:(uint64_t)suggestedAmount
{
    NSString *feeString = [NSNumberFormatter formatMoney:fee localCurrency:NO];
    NSString *suggestedFeeString = [NSNumberFormatter formatMoney:suggestedFee localCurrency:NO];
    NSString *suggestedAmountString = [NSNumberFormatter formatMoney:suggestedAmount localCurrency:NO];
    
    UIAlertController *alertForInsufficientFundsAndLowFee = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING_TITLE message:[NSString stringWithFormat:BC_STRING_FEE_LOWER_THAN_RECOMMENDED_ARGUMENT_MUST_LOWER_AMOUNT_SUGGESTED_FEE_ARGUMENT_SUGGESTED_AMOUNT_ARGUMENT, feeString, suggestedFeeString, suggestedAmountString] preferredStyle:UIAlertControllerStyleAlert];
    [alertForInsufficientFundsAndLowFee addAction:[UIAlertAction actionWithTitle:BC_STRING_KEEP_LOWER_FEE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self changeForcedFee:fee afterEvaluation:YES];
    }]];
    [alertForInsufficientFundsAndLowFee addAction:[UIAlertAction actionWithTitle:BC_STRING_USE_RECOMMENDED_VALUES style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        feeField.text = [NSNumberFormatter formatAmount:suggestedFee localCurrency:NO];
        amountInSatoshi = suggestedAmount;
        [self doCurrencyConversion];
        [self changeForcedFee:suggestedFee afterEvaluation:YES];
    }]];
    [alertForInsufficientFundsAndLowFee addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [app.tabViewController presentViewController:alertForInsufficientFundsAndLowFee animated:YES completion:nil];
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
    customFeeOriginalAvailableAmount = 0.0;
    
    [self reloadAfterMultiAddressResponse];
}

- (void)changeToDefaultFeeMode
{    
    [self arrangeViewsToDefaultMode];
    self.customFeeMode = NO;
    customFeeOriginalAvailableAmount = 0.0;
    
    [self reloadAfterMultiAddressResponse];
}

- (void)arrangeViewsToFeeMode
{
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        
        if ([[UIScreen mainScreen] bounds].size.height <= HEIGHT_IPHONE_4S) {
            [self changeYPosition:43 ofView:lineBelowFromField];
            
            [self changeYPosition:52 ofView:toLabel];
            [self changeYPosition:48 ofView:toField];
            [self changeYPosition:48 ofView:addressBookButton];
            [self changeYPosition:81 ofView:lineBelowToField];
            
            [self changeYPosition:88 ofView:bottomContainerView];
            [self changeYPosition:-1 ofView:btcLabel];
            [self changeYPosition:-5 ofView:btcAmountField];
            [self changeYPosition:-1 ofView:fiatLabel];
            [self changeYPosition:-5 ofView:fiatAmountField];
            [self changeYPosition:43 ofView:lineBelowAmountFields];
            
            [self changeYPosition:44 ofView:feeField];
            [self changeYPosition:47 ofView:feeLabel];
            [self changeYPosition:71 ofView:lineBelowFeeField];
            
            [self changeYPosition:21 ofView:fundsAvailableButton];
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
            [self changeYPosition:47 ofView:lineBelowFromField];
            
            [self changeYPosition:61 ofView:toLabel];
            [self changeYPosition:57 ofView:toField];
            [self changeYPosition:57 ofView:addressBookButton];
            [self changeYPosition:96 ofView:lineBelowToField];
            
            [self changeYPosition:98 ofView:bottomContainerView];
            [self changeYPosition:12 ofView:btcLabel];
            [self changeYPosition:8 ofView:btcAmountField];
            [self changeYPosition:12 ofView:fiatLabel];
            [self changeYPosition:8 ofView:fiatAmountField];
            [self changeYPosition:61 ofView:lineBelowAmountFields];
            
            [self changeYPosition:72 ofView:feeField];
            [self changeYPosition:75 ofView:feeLabel];
            [self changeYPosition:109 ofView:lineBelowFeeField];
            
            [self changeYPosition:36 ofView:fundsAvailableButton];
        }
        
        feeField.hidden = YES;
        feeLabel.hidden = YES;
        lineBelowFeeField.hidden = YES;
    }];
}

- (void)changeYPosition:(CGFloat)newY ofView:(UIView *)view
{
    view.frame = CGRectMake(view.frame.origin.x, newY, view.frame.size.width, view.frame.size.height);
}

- (void)updateSendBalance:(NSNumber *)balance
{
    uint64_t newBalance = [balance longLongValue] <= 0 ? 0 : [balance longLongValue];
    
    if (self.customFeeMode) {
        customFeeOriginalAvailableAmount = newBalance;
    }
    
    availableAmount = newBalance;
    
    if (!self.transferAllPaymentBuilder || self.transferAllPaymentBuilder.userCancelledNext) {
        [self doCurrencyConversionAfterMultiAddress];
    }
}

- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed
{
    if ([addressesUsed count] == 0) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self showErrorBeforeSending:BC_STRING_NO_ADDRESSES_WITH_SPENDABLE_BALANCE_ABOVE_OR_EQUAL_TO_DUST];
            [app hideBusyView];
        });
        return;
    }
    
    if ([amount longLongValue] + [fee longLongValue] > [app.wallet getTotalBalanceForSpendableActiveLegacyAddresses]) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [app standardNotifyAutoDismissingController:BC_STRING_SOME_FUNDS_CANNOT_BE_TRANSFERRED_AUTOMATICALLY title:BC_STRING_WARNING_TITLE];
            [app hideBusyView];
        });
    }
    
    self.fromAddress = @"";
    self.sendFromAddress = YES;
    self.sendToAddress = NO;
    self.toAccount = [app.wallet getDefaultAccountIndex];
    toField.text = [app.wallet getLabelForAccount:[app.wallet getDefaultAccountIndex]];
    
    self.feeFromTransactionProposal = [fee longLongValue];
    amountInSatoshi = [amount longLongValue];
        
    selectAddressTextField.text = [addressesUsed count] == 1 ? [NSString stringWithFormat:BC_STRING_ARGUMENT_ADDRESS, [addressesUsed count]] : [NSString stringWithFormat:BC_STRING_ARGUMENT_ADDRESSES, [addressesUsed count]];
    
    [self disablePaymentButtons];
    
    [self.transferAllPaymentBuilder setupFirstTransferWithAddressesUsed:addressesUsed];
}

- (void)showSummaryForTransferAll
{
    [app hideBusyView];
    
    [self showSummaryWithCustomFromLabel:selectAddressTextField.text];
    
    [self enablePaymentButtons];
    
    self.confirmPaymentView.customizeFeeButton.hidden = YES;
    sendProgressCancelButton.hidden = [self.transferAllPaymentBuilder.transferAllAddressesToTransfer count] <= 1;

    [self.confirmPaymentView.reallyDoPaymentButton removeTarget:self action:nil forControlEvents:UIControlEventAllTouchEvents];
    [self.confirmPaymentView.reallyDoPaymentButton addTarget:self action:@selector(transferAllFundsToDefaultAccount) forControlEvents:UIControlEventTouchUpInside];
}

- (BOOL)transferAllMode
{
    return self.transferAllPaymentBuilder && !self.transferAllPaymentBuilder.userCancelledNext;
}

#pragma mark - Textfield Delegates

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (![app.wallet isInitialized]) {
        DLog(@"Tried to access Send textField when not initialized!");
        return NO;
    }
    
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
    
    self.transactionType = TransactionTypeRegular;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == btcAmountField || textField == fiatAmountField || textField == feeField) {
        
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
        
        if (textField == feeField) {
            
            uint64_t fee = [app.wallet parseBitcoinValueFromString:newString];
            
            if (fee > BTC_LIMIT_IN_SATOSHI) {
                return NO;
            }
            
            uint64_t spendableAmount = 0;
            if (fee < customFeeOriginalAvailableAmount) {
                spendableAmount = customFeeOriginalAvailableAmount - fee;
            }
            availableAmount = spendableAmount;
            
            if (fee + amountInSatoshi > customFeeOriginalAvailableAmount) {
                textField.textColor = [UIColor redColor];
                [self disablePaymentButtons];
            } else {
                textField.textColor = [UIColor blackColor];
                [self enablePaymentButtons];
            }
            
            [self updateFundsAvailable];
            
            return YES;
        }
        
        if (textField == fiatAmountField) {
            // Convert input amount to internal value
            NSString *amountString = [newString stringByReplacingOccurrencesOfString:@"," withString:@"."];
            if (![amountString containsString:@"."]) {
                amountString = [newString stringByReplacingOccurrencesOfString:@"٫" withString:@"."];
            }
            amountInSatoshi = app.latestResponse.symbol_local.conversion * [amountString doubleValue];
        }
        else if (textField == btcAmountField) {
            amountInSatoshi = [app.wallet parseBitcoinValueFromString:newString];
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
            [self selectToAddress:self.toAddress];
            _addressSource = DestinationAddressSourcePaste;
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
    if (fiatAmountField.textColor == [UIColor redColor] && btcAmountField.textColor == [UIColor redColor] && [fiatAmountField.text isEqualToString:[NSNumberFormatter formatAmount:availableAmount localCurrency:YES]]) {
        [fundsAvailableButton setTitle:[NSString stringWithFormat:BC_STRING_USE_TOTAL_AVAILABLE_MINUS_FEE_ARGUMENT, [NSNumberFormatter formatMoney:availableAmount localCurrency:NO]] forState:UIControlStateNormal];
    } else {
        [fundsAvailableButton setTitle:[NSString stringWithFormat:BC_STRING_USE_TOTAL_AVAILABLE_MINUS_FEE_ARGUMENT,
                                        [NSNumberFormatter formatMoney:availableAmount localCurrency:displayingLocalSymbolSend]]
                              forState:UIControlStateNormal];
    }
}

- (void)selectToAddress:(NSString *)address
{
    self.sendToAddress = true;
    
    toField.text = [self labelForLegacyAddress:address];
    self.toAddress = address;
    DLog(@"toAddress: %@", address);
    
    [app.wallet changePaymentToAddress:address];
    
    [self doCurrencyConversion];
}

- (void)selectToAccount:(int)account
{
    self.sendToAddress = false;
    
    toField.text = [app.wallet getLabelForAccount:account];
    self.toAccount = account;
    self.toAddress = @"";
    DLog(@"toAccount: %@", [app.wallet getLabelForAccount:account]);
    
    [app.wallet changePaymentToAccount:account];
    
    [self doCurrencyConversion];
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
    
    selectAddressTextField.text = addressOrLabel;
    self.fromAddress = address;
    DLog(@"fromAddress: %@", address);
    
    [app.wallet changePaymentFromAddress:address isAdvanced:self.customFeeMode];
    
    [self doCurrencyConversion];
}

- (void)didSelectToAddress:(NSString *)address
{
    [self selectToAddress:address];
    
    _addressSource = DestinationAddressSourceDropDown;
}

- (void)didSelectFromAccount:(int)account
{
    self.sendFromAddress = false;
    
    availableAmount = [app.wallet getBalanceForAccount:account];
    
    selectAddressTextField.text = [app.wallet getLabelForAccount:account];
    self.fromAccount = account;
    DLog(@"fromAccount: %@", [app.wallet getLabelForAccount:account]);
    
    [app.wallet changePaymentFromAccount:account isAdvanced:self.customFeeMode];
    
    [self updateFundsAvailable];
    
    [self doCurrencyConversion];
}

- (void)didSelectToAccount:(int)account
{
    [self selectToAccount:account];
    
    _addressSource = DestinationAddressSourceDropDown;
}

#pragma mark - Fee Calculation

- (void)getTransactionFeeWithSuccess:(void (^)())success error:(void (^)())error
{
    self.getTransactionFeeSuccess = success;
    
    [app.wallet getTransactionFee];
}

- (void)didCheckForOverSpending:(NSNumber *)amount fee:(NSNumber *)fee
{
    if ([amount longLongValue] <= 0) {
        [self alertUserForZeroSpendableAmount];
        return;
    }
    
    self.feeFromTransactionProposal = [fee longLongValue];
    uint64_t maxAmount = [amount longLongValue];
    self.maxSendableAmount = maxAmount;
    
    if (amountInSatoshi > maxAmount) {
        [self showSweepConfirmationScreenWithMaxAmount:maxAmount];
    } else {
        // Underspending - regular transaction
        __weak SendViewController *weakSelf = self;
        
        [self getTransactionFeeWithSuccess:^{
            [weakSelf showSummary];
        } error:nil];
    }
}

- (void)didGetMaxFee:(NSNumber *)fee amount:(NSNumber *)amount dust:(NSNumber *)dust willConfirm:(BOOL)willConfirm
{
    if ([amount longLongValue] <= 0) {
        [self alertUserForZeroSpendableAmount];
        return;
    }
    
    self.feeFromTransactionProposal = [fee longLongValue];
    uint64_t maxAmount = [amount longLongValue];
    self.maxSendableAmount = maxAmount;
    self.dust = dust == nil ? 0 : [dust longLongValue];
    
    DLog(@"SendViewController: got max fee of %lld", [fee longLongValue]);
    amountInSatoshi = maxAmount;
    [self doCurrencyConversion];
    
    if (willConfirm) {
        [self showSummary];
    }
}

- (void)didGetFee:(NSNumber *)fee dust:(NSNumber *)dust txSize:(NSNumber *)txSize
{
    self.feeFromTransactionProposal = [fee longLongValue];
    self.recommendedForcedFee = [fee longLongValue];
    self.dust = dust == nil ? 0 : [dust longLongValue];
    self.txSize = [txSize longLongValue];
    
    if (self.getTransactionFeeSuccess) {
        self.getTransactionFeeSuccess();
    }
}

- (void)didChangeForcedFee:(NSNumber *)fee dust:(NSNumber *)dust
{
    self.feeFromTransactionProposal = [fee longLongValue];
    self.dust = dust == nil ? 0 : [dust longLongValue];
    [self showSummary];
}

- (void)checkMaxFee
{
    [app.wallet checkIfOverspending];
}

- (void)changeForcedFee:(uint64_t)absoluteFee afterEvaluation:(BOOL)afterEvaluation
{
    if (afterEvaluation) {
        [app.wallet changeForcedFee:absoluteFee];
    } else {
        [app.wallet getFeeBounds:[app.wallet parseBitcoinValueFromTextField:feeField]];
    }
}

- (void)didGetFeeBounds:(NSArray *)bounds confirmationEstimation:(NSNumber *)confirmationEstimation maxAmounts:(NSArray *)maxAmounts maxFees:(NSArray *)maxFees
{
    uint64_t typedFee = [app.wallet parseBitcoinValueFromTextField:feeField];
    
    if ([confirmationEstimation isMemberOfClass:[NSNull class]]) {
        [self showWarningForInsufficientFundsAndLowFee:typedFee suggestedFee:[[maxFees lastObject] longLongValue] suggestedAmount:[[maxAmounts lastObject] longLongValue]];
        return;
    }
    
    if ([confirmationEstimation intValue] < 0) {
        self.lowerRecommendedLimit = [[bounds lastObject] longLongValue];
        [self showWarningForFee:typedFee isHigherThanRecommendedRange:NO];
        return;
    }

    uint64_t expectedBlock = [confirmationEstimation longLongValue];
    
    if (expectedBlock >= 2 && expectedBlock <= 6) {
        [self changeForcedFeeAndUpdateValues];
        return;
    }
    
    if (expectedBlock == 1) {
        if (typedFee <= [[bounds firstObject] longLongValue]) {
            [self changeForcedFeeAndUpdateValues];
            return;
        } else {
            self.upperRecommendedLimit = [[bounds firstObject] longLongValue];
            [self showWarningForFee:typedFee isHigherThanRecommendedRange:YES];
            return;
        }
    }
}

- (void)changeForcedFeeAndUpdateValues
{
    uint64_t amountTotal = amountInSatoshi + self.feeFromTransactionProposal + self.dust;
    uint64_t feeTotal = self.dust + self.feeFromTransactionProposal;
    
    self.confirmPaymentView.fiatFeeLabel.text = [NSNumberFormatter formatMoney:feeTotal localCurrency:TRUE];
    self.confirmPaymentView.btcFeeLabel.text = [NSNumberFormatter formatMoney:feeTotal localCurrency:FALSE];
    
    self.confirmPaymentView.fiatTotalLabel.text = [NSNumberFormatter formatMoney:amountTotal localCurrency:TRUE];
    self.confirmPaymentView.btcTotalLabel.text = [NSNumberFormatter formatMoney:amountTotal localCurrency:FALSE];
    
    [app.wallet changeForcedFee:[app.wallet parseBitcoinValueFromTextField:feeField]];
}

#pragma mark - Actions

- (void)setupTransferAll
{
    self.transferAllPaymentBuilder = [[TransferAllFundsBuilder alloc] initUsingSendScreen:YES];
    self.transferAllPaymentBuilder.delegate = self;
}

- (void)archiveTransferredAddresses
{
    [app showBusyViewWithLoadingText:[NSString stringWithFormat:BC_STRING_ARCHIVING_ADDRESSES]];
                                      
    [app.wallet archiveTransferredAddresses:self.transferAllPaymentBuilder.transferAllAddressesTransferred];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(finishedArchivingTransferredAddresses) name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
}

- (void)finishedArchivingTransferredAddresses
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
    [app closeAllModals];
}

- (IBAction)selectFromAddressClicked:(id)sender
{
    if (![app.wallet isInitialized]) {
        DLog(@"Tried to access select from screen when not initialized!");
        return;
    }
    
    BCAddressSelectionView *addressSelectionView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet showOwnAddresses:YES allSelectable:NO accountsOnly:NO];
    addressSelectionView.delegate = self;
    
    [app showModalWithContent:addressSelectionView closeType:ModalCloseTypeBack showHeader:YES headerText:BC_STRING_SEND_FROM onDismiss:nil onResume:nil];
}

- (IBAction)addressBookClicked:(id)sender
{
    if (![app.wallet isInitialized]) {
        DLog(@"Tried to access select to screen when not initialized!");
        return;
    }
    
    BCAddressSelectionView *addressSelectionView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet showOwnAddresses:NO allSelectable:YES accountsOnly:NO];
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
                
                NSString *address = [dict objectForKey:DICTIONARY_KEY_ADDRESS];
                
                if (address == nil || ![app.wallet isBitcoinAddress:address]) {
                    [app standardNotify:[NSString stringWithFormat:BC_STRING_INVALID_ADDRESS_ARGUMENT, address]];
                    return;
                }
                
                toField.text = [self labelForLegacyAddress:address];
                self.toAddress = address;
                self.sendToAddress = true;
                DLog(@"toAddress: %@", self.toAddress);
                [self selectToAddress:self.toAddress];
                
                _addressSource = DestinationAddressSourceQR;
                
                NSString *amountStringFromDictionary = [dict objectForKey:DICTIONARY_KEY_AMOUNT];
                if ([NSNumberFormatter stringHasBitcoinValue:amountStringFromDictionary]) {
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
    
    if (self.customFeeMode) {
        
        uint64_t customFee = [app.wallet parseBitcoinValueFromTextField:feeField];
        
        if (customFee >= customFeeOriginalAvailableAmount) {
            [app standardNotifyAutoDismissingController:BC_STRING_PLEASE_LOWER_CUSTOM_FEE];
            return;
        }
        
        [app.wallet sweepPaymentAdvanced:customFee];
    } else {
        [app.wallet sweepPaymentRegular];
    }
    
    self.transactionType = TransactionTypeSweep;
}

- (IBAction)customizeFeeClicked:(UIButton *)sender
{
    [app closeModalWithTransition:kCATransitionFade];
    
    [self changeToCustomFeeMode];
    
    feeField.text = [NSNumberFormatter formatAmount:self.feeFromTransactionProposal localCurrency:NO];
}

- (IBAction)feeInformationClicked:(UIButton *)sender
{
    NSString *title = BC_STRING_FEE_INFORMATION_TITLE;
    NSString *message = BC_STRING_FEE_INFORMATION_MESSAGE;
    
    if (!self.customFeeMode) {
        message = [message stringByAppendingString:BC_STRING_FEE_INFORMATION_MESSAGE_APPEND_REGULAR_SEND];
    }
    
    if (self.surgeIsOccurring || [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_DEBUG_SIMULATE_SURGE]) {
        message = [message stringByAppendingString:[NSString stringWithFormat:@"\n\n%@", BC_STRING_SURGE_OCCURRING_MESSAGE]];
    }

    if (self.dust > 0) {
        message = [message stringByAppendingString:[NSString stringWithFormat:@"\n\n%@", BC_STRING_FEE_INFORMATION_DUST]];
    }

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    [self.view.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (IBAction)sendPaymentClicked:(id)sender
{
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
    // Convert input amount to internal value
    NSString *language = btcAmountField.textInputMode.primaryLanguage;
    NSLocale *locale = language ? [NSLocale localeWithLocaleIdentifier:language] : [NSLocale currentLocale];
    NSString *amountString = [btcAmountField.text stringByReplacingOccurrencesOfString:[locale objectForKey:NSLocaleDecimalSeparator] withString:@"."];
    
    NSString *europeanComma = @",";
    NSString *arabicComma= @"٫";
    
    if ([amountString containsString:europeanComma]) {
        amountString = [btcAmountField.text stringByReplacingOccurrencesOfString:europeanComma withString:@"."];
    } else if ([amountString containsString:arabicComma]) {
        amountString = [btcAmountField.text stringByReplacingOccurrencesOfString:arabicComma withString:@"."];
    }
    if (value <= 0 || [amountString doubleValue] <= 0) {
        [self showErrorBeforeSending:BC_STRING_INVALID_SEND_VALUE];
        return;
    }
    
    [self hideKeyboard];
    
    [self disablePaymentButtons];
    
    self.transactionType = TransactionTypeRegular;
    
    if (feeField.hidden) {
        [self checkMaxFee];
    } else {
        [self changeForcedFee:[app.wallet parseBitcoinValueFromTextField:feeField] afterEvaluation:NO];
    }
    
    [app.wallet getSurgeStatus];
    
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

//
//  TabControllerManager.m
//  Blockchain
//
//  Created by kevinwu on 8/21/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TabControllerManager.h"

@implementation TabControllerManager

- (instancetype)init
{
    if (self == [super init]) {
        self.tabViewController = [[[NSBundle mainBundle] loadNibNamed:NIB_NAME_TAB_CONTROLLER owner:self options:nil] firstObject];
        self.tabViewController.assetDelegate = self;
        
        NSInteger assetType = [[[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_ASSET_TYPE] integerValue];
        self.assetType = assetType;
        [self.tabViewController.assetSegmentedControl setSelectedSegmentIndex:assetType];
    }
    return self;
}

- (void)didSetAssetType:(AssetType)assetType
{
    self.assetType = assetType;
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithInteger:self.assetType] forKey:USER_DEFAULTS_KEY_ASSET_TYPE];
    
    if (self.tabViewController.selectedIndex == TAB_SEND) {
        [self showSendCoins];
    } else if (self.tabViewController.selectedIndex == TAB_DASHBOARD) {
        [self showDashboard];
    } else if (self.tabViewController.selectedIndex == TAB_TRANSACTIONS) {
        [self showTransactions];
    } else if (self.tabViewController.selectedIndex == TAB_RECEIVE) {
        [self showReceive];
    }
}

- (void)reload
{
    [_sendBitcoinViewController reload];
    [_sendEtherViewController reload];
    [_transactionsBitcoinViewController reload];
    [_transactionsEtherViewController reload];
    [_receiveViewController reload];
}

- (void)reloadAfterMultiAddressResponse
{
    [_dashboardViewController reload];
    [_sendBitcoinViewController reloadAfterMultiAddressResponse];
    [_transactionsBitcoinViewController reload];
    [_receiveViewController reload];
}

- (void)reloadMessageViews
{
    [self.sendBitcoinViewController hideSelectFromAndToButtonsIfAppropriate];
    
    [_transactionsBitcoinViewController didGetMessages];
}

- (void)logout
{
    [self updateTransactionsViewControllerData:nil];
    [_receiveViewController clearAmounts];
}

- (void)forgetWallet
{
    self.receiveViewController = nil;
    [_transactionsBitcoinViewController setData:nil];
}

#pragma mark - BTC Send

- (BOOL)isSending
{
    return self.sendBitcoinViewController.isSending;
}

- (void)showSendCoins
{
    if (self.assetType == AssetTypeBitcoin) {
        if (!_sendBitcoinViewController) {
            _sendBitcoinViewController = [[SendBitcoinViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
        }
        
        [_tabViewController setActiveViewController:_sendBitcoinViewController animated:TRUE index:TAB_SEND];
    } else if (self.assetType == AssetTypeEther) {
        if (!_sendEtherViewController) {
            _sendEtherViewController = [[SendEtherViewController alloc] init];
        }
        
        [_tabViewController setActiveViewController:_sendEtherViewController animated:TRUE index:TAB_SEND];
        [_sendEtherViewController getHistory];
    }
}

- (void)setupTransferAllFunds
{
    if (!_sendBitcoinViewController) {
       _sendBitcoinViewController = [[SendBitcoinViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
    }
    
    [self showSendCoins];
    
    [_sendBitcoinViewController setupTransferAll];
}

- (void)QRCodeButtonClicked
{
    if (!_sendBitcoinViewController) {
        _sendBitcoinViewController = [[SendBitcoinViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
    }
    
    if (_receiveViewController) {
        [_receiveViewController hideKeyboard];
    }
    
    [_sendBitcoinViewController QRCodebuttonClicked:nil];
}

- (void)hideSendKeyboard
{
    [self.sendBitcoinViewController hideKeyboard];
}

- (DestinationAddressSource)getSendAddressSource
{
    return self.sendBitcoinViewController.addressSource;
}

- (void)setupPaymentRequest:(ContactTransaction *)transaction
{
    if (!_sendBitcoinViewController) {
        _sendBitcoinViewController = [[SendBitcoinViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
    }
    
    [self showSendCoins];
    [_sendBitcoinViewController setupPaymentRequest:transaction];
}

- (void)setupSendToAddress:(NSString *)address
{
    [self showSendCoins];
    
    self.sendBitcoinViewController.addressFromURLHandler = address;
    [self.sendBitcoinViewController reload];
}

- (void)sendFromWatchOnlyAddress
{
    [_sendBitcoinViewController sendFromWatchOnlyAddress];
}

- (void)didCheckForOverSpending:(NSNumber *)amount fee:(NSNumber *)fee
{
    [_sendBitcoinViewController didCheckForOverSpending:amount fee:fee];
}

- (void)didGetMaxFee:(NSNumber *)fee amount:(NSNumber *)amount dust:(NSNumber *)dust willConfirm:(BOOL)willConfirm
{
    [_sendBitcoinViewController didGetMaxFee:fee amount:amount dust:dust willConfirm:willConfirm];
}

- (void)didUpdateTotalAvailable:(NSNumber *)sweepAmount finalFee:(NSNumber *)finalFee
{
    [_sendBitcoinViewController didUpdateTotalAvailable:sweepAmount finalFee:finalFee];
}

- (void)didGetFee:(NSNumber *)fee dust:(NSNumber *)dust txSize:(NSNumber *)txSize
{
    [_sendBitcoinViewController didGetFee:fee dust:dust txSize:txSize];
}

- (void)didChangeSatoshiPerByte:(NSNumber *)sweepAmount fee:(NSNumber *)fee dust:(NSNumber *)dust updateType:(FeeUpdateType)updateType
{
    [_sendBitcoinViewController didChangeSatoshiPerByte:sweepAmount fee:fee dust:dust updateType:updateType];
}

- (void)didGetSurgeStatus:(BOOL)surgeStatus
{
    _sendBitcoinViewController.surgeIsOccurring = surgeStatus;
}

- (void)updateSendBalance:(NSNumber *)balance fees:(NSDictionary *)fees
{
    [_sendBitcoinViewController updateSendBalance:balance fees:fees];
}

- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed
{
    [_sendBitcoinViewController updateTransferAllAmount:amount fee:fee addressesUsed:addressesUsed];
}

- (void)showSummaryForTransferAll
{
    [_sendBitcoinViewController showSummaryForTransferAll];
}

- (void)sendDuringTransferAll:(NSString *)secondPassword
{
    [self.sendBitcoinViewController sendDuringTransferAll:secondPassword];
}

- (void)didErrorDuringTransferAll:(NSString *)error secondPassword:(NSString *)secondPassword
{
    [_sendBitcoinViewController didErrorDuringTransferAll:error secondPassword:secondPassword];
}

- (void)updateLoadedAllTransactions:(NSNumber *)loadedAll
{
    _transactionsBitcoinViewController.loadedAllTransactions = [loadedAll boolValue];
}

- (void)receivedTransactionMessage
{
    [_transactionsBitcoinViewController didReceiveTransactionMessage];
    
    [_receiveViewController storeRequestedAmount];
}

#pragma mark - Eth Send

- (void)didUpdateEthPayment:(NSDictionary *)ethPayment
{
    [_sendEtherViewController didUpdatePayment:ethPayment];
}

- (void)didSendEther
{
    [self.tabViewController didSendEther];
    [self showTransactions];
}

- (void)didErrorDuringEtherSend:(NSString *)error
{
    [self.tabViewController didErrorDuringEtherSend:error];
}

- (void)didFetchEthExchangeRate:(NSNumber *)rate
{
    self.latestEthExchangeRate = [NSDecimalNumber decimalNumberWithDecimal:[rate decimalValue]];

    [self.tabViewController didFetchEthExchangeRate];
    [_sendEtherViewController updateExchangeRate:self.latestEthExchangeRate];
    [_dashboardViewController updateEthExchangeRate:self.latestEthExchangeRate];
}

#pragma mark - Receive

- (void)showReceive
{
    if (self.assetType == AssetTypeBitcoin) {
        if (!_receiveViewController) {
            _receiveViewController = [[ReceiveCoinsViewController alloc] initWithNibName:NIB_NAME_RECEIVE_COINS bundle:[NSBundle mainBundle]];
        }
        
        [_tabViewController setActiveViewController:_receiveViewController animated:TRUE index:TAB_RECEIVE];
    } else if (self.assetType == AssetTypeEther) {
        if (!_receiveEtherViewController) {
            _receiveEtherViewController = [[ReceiveEtherViewController alloc] init];
        }
        
        [_tabViewController setActiveViewController:_receiveEtherViewController animated:TRUE index:TAB_RECEIVE];
    }
}

- (void)clearReceiveAmounts
{
    [self.receiveViewController clearAmounts];
}

- (void)didSetDefaultAccount
{
    [self.receiveViewController reloadMainAddress];
}

- (void)paymentReceived:(NSDecimalNumber *)amount showBackupReminder:(BOOL)showBackupReminder
{
    [_receiveViewController paymentReceived:amount showBackupReminder:showBackupReminder];
}

- (NSDecimalNumber *)lastEthExchangeRate
{
    return self.latestEthExchangeRate;
}

#pragma mark - Dashboard

- (void)showDashboard
{
    if (!_dashboardViewController) {
        DashboardViewController *dashboardViewController = [DashboardViewController new];
        self.dashboardViewController = dashboardViewController;
    }
    
    [_tabViewController setActiveViewController:self.dashboardViewController animated:TRUE index:TAB_DASHBOARD];
    
    self.dashboardViewController.assetType = self.assetType;
}

#pragma mark - Transactions

- (void)showTransactions
{
    if (self.assetType == AssetTypeBitcoin) {
        if (!_transactionsBitcoinViewController) {
            _transactionsBitcoinViewController = [[[NSBundle mainBundle] loadNibNamed:NIB_NAME_TRANSACTIONS owner:self options:nil] firstObject];
        }
        
        [_tabViewController setActiveViewController:_transactionsBitcoinViewController animated:NO index:TAB_TRANSACTIONS];
    } else if (self.assetType == AssetTypeEther) {
        if (!_transactionsEtherViewController) {
            _transactionsEtherViewController = [[TransactionsEtherViewController alloc] init];
        }
        
        [_tabViewController setActiveViewController:_transactionsEtherViewController animated:NO index:TAB_TRANSACTIONS];
    }
}

- (void)didChangeLocalCurrency
{
    [self.sendBitcoinViewController reloadFeeAmountLabel];
    [self.receiveViewController doCurrencyConversion];
}

- (void)setupBitcoinPaymentFromURLHandlerWithAmountString:(NSString *)amountString address:(NSString *)address
{
    if (!self.sendBitcoinViewController) {
        // really no reason to lazyload anymore...
        _sendBitcoinViewController = [[SendBitcoinViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
    }
    
    [_sendBitcoinViewController setAmountStringFromUrlHandler:amountString withToAddress:address];
    [_sendBitcoinViewController reload];
}

- (void)filterTransactionsByAccount:(int)accountIndex filterLabel:(NSString *)filterLabel
{
    _transactionsBitcoinViewController.clickedFetchMore = NO;
    _transactionsBitcoinViewController.filterIndex = accountIndex;
    [_transactionsBitcoinViewController changeFilterLabel:filterLabel];
    
    [_sendBitcoinViewController resetFromAddress];
    [_receiveViewController reloadMainAddress];
}

- (NSInteger)getFilterIndex
{
    return _transactionsBitcoinViewController.filterIndex;
}

- (void)filterTransactionsByImportedAddresses
{
    _transactionsBitcoinViewController.clickedFetchMore = NO;
    _transactionsBitcoinViewController.filterIndex = FILTER_INDEX_IMPORTED_ADDRESSES;
    [_transactionsBitcoinViewController changeFilterLabel:BC_STRING_IMPORTED_ADDRESSES];
}

- (void)removeTransactionsFilter
{
    _transactionsBitcoinViewController.clickedFetchMore = NO;
    _transactionsBitcoinViewController.filterIndex = FILTER_INDEX_ALL;
}

- (void)selectPayment:(NSString *)payment
{
    [self.transactionsBitcoinViewController selectPayment:payment];
}

- (void)showTransactionDetailForHash:(NSString *)hash
{
    [self.transactionsBitcoinViewController showTransactionDetailForHash:hash];
}

- (void)setTransactionsViewControllerMessageIdentifier:(NSString *)identifier
{
    self.transactionsBitcoinViewController.messageIdentifier = identifier;
}

- (void)showFilterResults
{
    [_tabViewController setActiveViewController:_transactionsBitcoinViewController animated:FALSE index:1];
}

- (void)selectorButtonClicked
{
    [_transactionsBitcoinViewController showFilterMenu];
}

#pragma mark - Reloading

- (void)reloadSymbols
{
    [_sendBitcoinViewController reloadSymbols];
    [_transactionsBitcoinViewController reloadSymbols];
}

- (void)reloadSendController
{
    [_sendBitcoinViewController reload];
}

- (void)clearSendToAddressAndAmountFields
{
    [self.sendBitcoinViewController clearToAddressAndAmountFields];
}

- (void)enableSendPaymentButtons
{
    [self.sendBitcoinViewController enablePaymentButtons];
}

- (BOOL)isSendViewControllerTransferringAll
{
    return _sendBitcoinViewController.transferAllMode;
}

- (void)transferFundsToDefaultAccountFromAddress:(NSString *)address
{
    if (!_sendBitcoinViewController) {
        _sendBitcoinViewController = [[SendBitcoinViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
    }
    
    [_sendBitcoinViewController transferFundsToDefaultAccountFromAddress:address];
}

- (void)didRejectContactTransaction
{
    [self.sendBitcoinViewController reload];
    [self showTransactions];
}

- (void)hideSendAndReceiveKeyboards
{
    // Dismiss sendviewController keyboard
    if (_sendBitcoinViewController) {
        [_sendBitcoinViewController hideKeyboardForced];
        
        // Make sure the the send payment button on send screen is enabled (bug when second password requested and app is backgrounded)
        [_sendBitcoinViewController enablePaymentButtons];
    }
    
    // Dismiss receiveCoinsViewController keyboard
    if (_receiveViewController) {
        [_receiveViewController hideKeyboardForced];
    }
}

- (void)updateTransactionsViewControllerData:(MultiAddressResponse *)data
{
    [_transactionsBitcoinViewController updateData:data];
}

- (void)didSetLatestBlock:(LatestBlock *)block
{
    _transactionsBitcoinViewController.latestBlock = block;
    [_transactionsBitcoinViewController reload];
}

- (void)didGetMessagesOnFirstLoad
{
    if (_transactionsBitcoinViewController.messageIdentifier) {
        [_transactionsBitcoinViewController selectPayment:_transactionsBitcoinViewController.messageIdentifier];
    }
}

- (void)updateBadgeNumber:(NSInteger)number forSelectedIndex:(int)index
{
    [self.tabViewController updateBadgeNumber:number forSelectedIndex:index];
}

#pragma mark - Navigation

- (IBAction)menuButtonClicked:(UIButton *)sender
{
    if (self.sendBitcoinViewController) {
        [self hideSendKeyboard];
    }
    
    [self.delegate toggleSideMenu];
}

- (void)dashBoardClicked:(UITabBarItem *)sender
{
    [self showDashboard];
}

- (void)receiveCoinClicked:(UITabBarItem *)sender
{
    [self showReceive];
}

- (void)transactionsClicked:(UITabBarItem *)sender
{
    [self showTransactions];
    
    if (sender &&
        [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAUTS_KEY_HAS_ENDED_FIRST_SESSION] &&
        ![[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_HAS_SEEN_SURVEY_PROMPT]) {
        
        NSDateFormatter *dateFormat = [[NSDateFormatter alloc] init];
        [dateFormat setDateFormat:@"MM dd, yyyy"];
        NSDate *endSurveyDate = [dateFormat dateFromString:DATE_SURVEY_END];
        
        if ([endSurveyDate timeIntervalSinceNow] > 0.0) {
            [self performSelector:@selector(showSurveyAlert) withObject:nil afterDelay:ANIMATION_DURATION];
        }
    }
}

- (void)showSurveyAlert
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_SURVEY_ALERT_TITLE message:BC_STRING_SURVEY_ALERT_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_YES style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        NSURL *settingsURL = [NSURL URLWithString:URL_SURVEY];
        [[UIApplication sharedApplication] openURL:settingsURL];
    }]];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_NOT_NOW style:UIAlertActionStyleCancel handler:nil]];
    
    [self.tabViewController presentViewController:alert animated:YES completion:nil];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_KEY_HAS_SEEN_SURVEY_PROMPT];
}

- (void)sendCoinsClicked:(UITabBarItem *)sender
{
    [self showSendCoins];
}

- (void)qrCodeButtonClicked
{
    if (self.assetType == AssetTypeBitcoin) {
        if (!_sendBitcoinViewController) {
            _sendBitcoinViewController = [[SendBitcoinViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
        }
        
        [_sendBitcoinViewController QRCodebuttonClicked:nil];
        
        [_tabViewController setActiveViewController:_sendBitcoinViewController animated:NO index:TAB_SEND];
    } else if (self.assetType == AssetTypeEther) {
        if (!_sendEtherViewController) {
            _sendEtherViewController = [[SendEtherViewController alloc] init];
        }
        
        [_sendEtherViewController QRCodebuttonClicked:nil];
        
        [_tabViewController setActiveViewController:_sendEtherViewController animated:NO index:TAB_SEND];
    }
}

@end

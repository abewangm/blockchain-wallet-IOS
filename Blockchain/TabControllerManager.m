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
    
    if (self.tabViewController.selectedIndex == TAB_SEND) {
        [self showSendCoins];
    }
}

- (void)reload
{
    [_sendBitcoinViewController reload];
    [_transactionsViewController reload];
    [_receiveViewController reload];
}

- (void)reloadAfterMultiAddressResponse
{
    [_dashboardViewController reload];
    [_sendBitcoinViewController reloadAfterMultiAddressResponse];
    [_transactionsViewController reload];
    [_receiveViewController reload];
}

- (void)reloadMessageViews
{
    [self.sendBitcoinViewController hideSelectFromAndToButtonsIfAppropriate];
    
    [_transactionsViewController didGetMessages];
}

- (void)logout
{
    [self updateTransactionsViewControllerData:nil];
    [_receiveViewController clearAmounts];
}

- (void)forgetWallet
{
    self.receiveViewController = nil;
    [_transactionsViewController setData:nil];
}

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
    _transactionsViewController.loadedAllTransactions = [loadedAll boolValue];
}

- (void)receivedTransactionMessage
{
    [_transactionsViewController didReceiveTransactionMessage];
    
    [_receiveViewController storeRequestedAmount];
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
    _transactionsViewController.clickedFetchMore = NO;
    _transactionsViewController.filterIndex = accountIndex;
    [_transactionsViewController changeFilterLabel:filterLabel];
    
    [_sendBitcoinViewController resetFromAddress];
    [_receiveViewController reloadMainAddress];
}

- (NSInteger)getFilterIndex
{
    return _transactionsViewController.filterIndex;
}

- (void)filterTransactionsByImportedAddresses
{
    _transactionsViewController.clickedFetchMore = NO;
    _transactionsViewController.filterIndex = FILTER_INDEX_IMPORTED_ADDRESSES;
    [_transactionsViewController changeFilterLabel:BC_STRING_IMPORTED_ADDRESSES];
}

- (void)removeTransactionsFilter
{
    _transactionsViewController.clickedFetchMore = NO;
    _transactionsViewController.filterIndex = FILTER_INDEX_ALL;
}

- (void)selectPayment:(NSString *)payment
{
    [self.transactionsViewController selectPayment:payment];
}

- (void)showTransactionDetailForHash:(NSString *)hash
{
    [self.transactionsViewController showTransactionDetailForHash:hash];
}

- (void)setTransactionsViewControllerMessageIdentifier:(NSString *)identifier
{
    self.transactionsViewController.messageIdentifier = identifier;
}

- (void)showFilterResults
{
    [_tabViewController setActiveViewController:_transactionsViewController animated:FALSE index:1];
}

- (void)reloadSymbols
{
    [_sendBitcoinViewController reloadSymbols];
    [_transactionsViewController reloadSymbols];
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

- (void)showTransactions
{
    if (!_transactionsViewController) {
        _transactionsViewController = [[[NSBundle mainBundle] loadNibNamed:NIB_NAME_TRANSACTIONS owner:self options:nil] firstObject];
    }
    
    [_tabViewController setActiveViewController:_transactionsViewController animated:NO index:TAB_TRANSACTIONS];
}

- (void)updateTransactionsViewControllerData:(MultiAddressResponse *)data
{
    [_transactionsViewController updateData:data];
}

- (void)didSetLatestBlock:(LatestBlock *)block
{
    _transactionsViewController.latestBlock = block;
    [_transactionsViewController reload];
}

- (void)didGetMessagesOnFirstLoad
{
    if (_transactionsViewController.messageIdentifier) {
        [_transactionsViewController selectPayment:_transactionsViewController.messageIdentifier];
    }
}

- (void)updateBadgeNumber:(NSInteger)number forSelectedIndex:(int)index
{
    [self.tabViewController updateBadgeNumber:number forSelectedIndex:index];
}

- (IBAction)menuButtonClicked:(UIButton *)sender
{
    if (self.sendBitcoinViewController) {
        [self hideSendKeyboard];
    }
    
    [self.delegate toggleSideMenu];
}

- (void)dashBoardClicked:(UITabBarItem *)sender
{
    if (!_dashboardViewController) {
        DashboardViewController *dashboardViewController = [DashboardViewController new];
        self.dashboardViewController = dashboardViewController;
    }
    
    [_tabViewController setActiveViewController:self.dashboardViewController animated:TRUE index:TAB_DASHBOARD];
}

- (void)receiveCoinClicked:(UITabBarItem *)sender
{
    if (!_receiveViewController) {
        _receiveViewController = [[ReceiveCoinsViewController alloc] initWithNibName:NIB_NAME_RECEIVE_COINS bundle:[NSBundle mainBundle]];
    }
    
    [_tabViewController setActiveViewController:_receiveViewController animated:TRUE index:TAB_RECEIVE];
}

- (void)transactionsClicked:(UITabBarItem *)sender
{
    if (!_transactionsViewController) {
        _transactionsViewController = [[[NSBundle mainBundle] loadNibNamed:NIB_NAME_TRANSACTIONS owner:self options:nil] firstObject];
    }
    
    [_tabViewController setActiveViewController:_transactionsViewController animated:TRUE index:TAB_TRANSACTIONS];
    
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

@end

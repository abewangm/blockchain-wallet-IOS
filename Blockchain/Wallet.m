//
//  Wallet.m
//  Blockchain
//
//  Created by Ben Reeves on 16/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "Wallet.h"
#import "AppDelegate.h"
#import "Transaction.h"
#import "NSString+NSString_EscapeQuotes.h"
#import "MultiAddressResponse.h"
#import "UncaughtExceptionHandler.h"
#import "NSString+JSONParser_NSString.h"
#import "NSString+NSString_EscapeQuotes.h"
#import "crypto_scrypt.h"
#import "NSData+Hex.h"
#import "TransactionsViewController.h"
#import "NSArray+EncodedJSONString.h"

@implementation transactionProgressListeners
@end

@implementation Key
@synthesize addr;
@synthesize priv;
@synthesize tag;
@synthesize label;

- (NSString *)description
{
    return [NSString stringWithFormat:@"<Key : addr %@, tag, %d>", addr, tag];
}

- (NSComparisonResult)compare:(Key *)otherObject
{
    return [self.addr compare:otherObject.addr];
}

@end

@implementation Wallet

@synthesize delegate;
@synthesize password;
@synthesize webView;
@synthesize sharedKey;
@synthesize guid;

- (id)init
{
    self = [super init];
    
    if (self) {
        _transactionProgressListeners = [NSMutableDictionary dictionary];
        webView = [[JSBridgeWebView alloc] initWithFrame:CGRectZero];
        webView.JSDelegate = self;
    }
    
    return self;
}

- (void)dealloc
{
    self.webView.JSDelegate = nil;
}

- (void)apiGetPINValue:(NSString*)key pin:(NSString*)pin
{
    [self loadJS];
    
    [self useDebugSettingsIfSet];
    
    [self.webView executeJS:@"MyWalletPhone.apiGetPINValue(\"%@\", \"%@\")", key, pin];
}

- (void)loadWalletWithGuid:(NSString*)_guid sharedKey:(NSString*)_sharedKey password:(NSString*)_password
{
    // DLog(@"guid: %@, password: %@", _guid, _password);
    self.guid = _guid;
    // Shared Key can be empty
    self.sharedKey = _sharedKey;
    self.password = _password;
    
    // Load the JS. Proceed in the webViewDidFinishLoad callback
    [self loadJS];
}

- (void)loadBlankWallet
{
    [self loadWalletWithGuid:nil sharedKey:nil password:nil];
}

- (void)loadJS
{
    NSError *error = nil;
    NSString *walletHTML = [NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"wallet-ios" ofType:@"html"] encoding:NSUTF8StringEncoding error:&error];
    
    NSMutableString *connectSrcString = [NSMutableString stringWithString:HTML_CONNECT_SRC_DEFAULT];

    // Append debug endpoints to the connect-src of the content security policy
#ifdef ENABLE_DEBUG_MENU
    [connectSrcString appendString:[NSString stringWithFormat:@" %@", [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL]]];
    [connectSrcString appendString:[NSString stringWithFormat:@" %@", [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL]]];
    [connectSrcString appendString:[NSString stringWithFormat:@" %@", [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_MERCHANT_URL]]];
    [connectSrcString appendString:[NSString stringWithFormat:@" %@", [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_API_URL]]];
#endif
    
    walletHTML = [walletHTML stringByReplacingOccurrencesOfString:HTML_CONNECT_SRC_PLACEHOLDER withString:connectSrcString];
    
    NSURL *baseURL = [NSURL fileURLWithPath:[[NSBundle mainBundle] resourcePath]];
    
    [webView loadHTMLString:walletHTML baseURL:baseURL];
}

#pragma mark - WebView handlers

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    DLog(@"webViewDidStartLoad:");
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    DLog(@"WebView: didFailLoadWithError:");
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    DLog(@"webViewDidFinishLoad:");
    
    [self useDebugSettingsIfSet];
    
    if (self.isNew) {
        [self getAllCurrencySymbols];
    }
    
    if ([delegate respondsToSelector:@selector(walletJSReady)])
        [delegate walletJSReady];
    
    if ([delegate respondsToSelector:@selector(walletDidLoad)])
        [delegate walletDidLoad];
    
    if (self.guid && self.password) {
        DLog(@"Fetch Wallet");
        
        NSString *escapedSharedKey = self.sharedKey == nil ? @"" : [self.sharedKey escapeStringForJS];
        NSString *escapedSessionToken = self.sessionToken == nil ? @"" : [self.sessionToken escapeStringForJS];
        NSString *escapedTwoFactorInput = self.twoFactorInput == nil ? @"" : [self.twoFactorInput escapeStringForJS];
        
        [self.webView executeJS:@"MyWalletPhone.login(\"%@\", \"%@\", false, \"%@\", \"%@\", \"%@\")", [self.guid escapeStringForJS], escapedSharedKey, [self.password escapeStringForJS], escapedSessionToken, escapedTwoFactorInput];
    }
}

# pragma mark - Calls from Obj-C to JS

- (BOOL)isInitialized
{
    // Initialized when the webView is loaded and the wallet is initialized (decrypted and in-memory wallet built)
    BOOL isInitialized = ([self.webView isLoaded] &&
            [[self.webView executeJSSynchronous:@"MyWallet.getIsInitialized()"] boolValue]);
    if (!isInitialized) {
        DLog(@"Warning: Wallet not initialized!");
    }
    
    return isInitialized;
}

- (BOOL)hasEncryptedWalletData
{
    if ([self isInitialized])
        return [[self.webView executeJSSynchronous:@"MyWalletPhone.hasEncryptedWalletData()"] boolValue];
    else
        return NO;
}

- (void)pinServerPutKeyOnPinServerServer:(NSString*)key value:(NSString*)value pin:(NSString*)pin
{
    if (![self isInitialized]) {
        return;
    }
    [self.webView executeJS:@"MyWalletPhone.pinServerPutKeyOnPinServerServer(\"%@\", \"%@\", \"%@\")", key, value, pin];
}

- (NSString*)encrypt:(NSString*)data password:(NSString*)_password pbkdf2_iterations:(int)pbkdf2_iterations
{
    return [self.webView executeJSSynchronous:@"WalletCrypto.encrypt(\"%@\", \"%@\", %d)", [data escapeStringForJS], [_password escapeStringForJS], pbkdf2_iterations];
}

- (NSString*)decrypt:(NSString*)data password:(NSString*)_password pbkdf2_iterations:(int)pbkdf2_iterations
{
    return [self.webView executeJSSynchronous:@"WalletCrypto.decryptPasswordWithProcessedPin(\"%@\", \"%@\", %d)", [data escapeStringForJS], [_password escapeStringForJS], pbkdf2_iterations];
}

- (float)getStrengthForPassword:(NSString *)passwordString
{
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.get_password_strength(\"%@\")", [passwordString escapeStringForJS]] floatValue];
}

- (void)getHistory
{
    if ([self isInitialized])
        [self.webView executeJS:@"MyWalletPhone.get_history()"];
}

- (void)getWalletAndHistory
{
    if ([self isInitialized])
        [self.webView executeJS:@"MyWalletPhone.get_wallet_and_history()"];
}

- (void)getHistoryIfNoTransactionMessage
{
    if (!self.didReceiveMessageForLastTransaction) {
        DLog(@"Did not receive tx message for %f seconds - getting history", DELAY_GET_HISTORY_BACKUP);
        [self getHistory];
    }
}

- (void)fetchMoreTransactions
{
    if ([self isInitialized]) {
        self.isFetchingTransactions = YES;
        [self.webView executeJS:@"MyWalletPhone.fetchMoreTransactions()"];
    }
}

- (int)getAllTransactionsCount
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.getAllTransactionsCount()"] intValue];
}

- (void)getAllCurrencySymbols
{
    if (![self.webView isLoaded]) {
        return;
    }
    
    [self.webView executeJS:@"JSON.stringify(MyWalletPhone.get_all_currency_symbols())"];
}

- (void)changeLocalCurrency:(NSString *)currencyCode
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.change_local_currency(\"%@\")", [currencyCode escapeStringForJS]];
}

- (void)changeBtcCurrency:(NSString *)btcCode
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.change_btc_currency(\"%@\")", [btcCode escapeStringForJS]];
}

- (void)getAccountInfo
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"JSON.stringify(MyWalletPhone.get_account_info())"];
}

- (void)changeEmail:(NSString *)newEmail
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.change_email_account(\"%@\")", [newEmail escapeStringForJS]];
}

- (void)resendVerificationEmail:(NSString *)email
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.resend_verification_email(\"%@\")", [email escapeStringForJS]];
}

- (void)changeMobileNumber:(NSString *)newMobileNumber
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.change_mobile_number(\"%@\")", [newMobileNumber escapeStringForJS]];
}

- (void)verifyMobileNumber:(NSString *)code
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.verify_mobile_number(\"%@\")", [code escapeStringForJS]];
}

- (void)enableTwoStepVerificationForSMS
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.enable_two_step_verification_sms()"];
}

- (void)disableTwoStepVerification
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.disable_two_step_verification()"];
}

- (void)updatePasswordHint:(NSString *)hint
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.update_password_hint(\"%@\")", [hint escapeStringForJS]];
}

- (void)changePassword:(NSString *)changedPassword
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.change_password(\"%@\")", [changedPassword escapeStringForJS]];
}

- (BOOL)isCorrectPassword:(NSString *)inputedPassword
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.isCorrectMainPassword(\"%@\")", [inputedPassword escapeStringForJS]] boolValue];
}

- (void)sendPaymentWithListener:(transactionProgressListeners*)listener secondPassword:(NSString *)secondPassword
{
    NSString * txProgressID;
    
    if (secondPassword) {
        txProgressID = [self.webView executeJSSynchronous:@"MyWalletPhone.quickSend(\"%@\")", [secondPassword escapeStringForJS]];
    } else {
        txProgressID = [self.webView executeJSSynchronous:@"MyWalletPhone.quickSend()"];
    }
    
    if (listener) {
        [self.transactionProgressListeners setObject:listener forKey:txProgressID];
    }
}

- (uint64_t)parseBitcoinValue:(NSString*)input
{
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"Helpers.precisionToSatoshiBN(\"%@\").toString()", [input escapeStringForJS]] longLongValue];
}

// Make a request to blockchain.info to get the session id SID in a cookie. This cookie is around for new instances of UIWebView and will be used to let the server know the user is trying to gain access from a new device. The device is recognized based on the SID.
- (void)loadWalletLogin
{
    if (!self.sessionToken) {
        [self getSessionToken];
    }
}

- (void)parsePairingCode:(NSString*)code
{
    [self useDebugSettingsIfSet];
    [self.webView executeJS:@"MyWalletPhone.parsePairingCode(\"%@\");", [code escapeStringForJS]];
}

// Pairing code JS callbacks

- (void)didParsePairingCode:(NSDictionary *)dict
{
    DLog(@"didParsePairingCode:");

    if ([delegate respondsToSelector:@selector(didParsePairingCode:)])
        [delegate didParsePairingCode:dict];
}

- (void)errorParsingPairingCode:(NSString *)message
{
    DLog(@"errorParsingPairingCode:");
    
    if ([delegate respondsToSelector:@selector(errorParsingPairingCode:)])
        [delegate errorParsingPairingCode:message];
}

- (void)newAccount:(NSString*)__password email:(NSString *)__email
{
    [self.webView executeJS:@"MyWalletPhone.newAccount(\"%@\", \"%@\", \"%@\")", [__password escapeStringForJS], [__email escapeStringForJS], BC_STRING_MY_BITCOIN_WALLET];
}

- (BOOL)needsSecondPassword
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.isDoubleEncrypted"] boolValue];
}

- (BOOL)validateSecondPassword:(NSString*)secondPassword
{
    if (![self isInitialized]) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.validateSecondPassword(\"%@\")", [secondPassword escapeStringForJS]] boolValue];
}

- (void)getFinalBalance
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJSWithCallback:^(NSString * final_balance) {
        self.final_balance = [final_balance longLongValue];
    } command:@"MyWallet.wallet.finalBalance"];
}

- (void)getTotalSent
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJSWithCallback:^(NSString * total_sent) {
        self.total_sent = [total_sent longLongValue];
    } command:@"MyWallet.wallet.totalSent"];
}

- (BOOL)isWatchOnlyLegacyAddress:(NSString*)address
{
    if (![self isInitialized]) {
        return false;
    }
    
    if ([self checkIfWalletHasAddress:address]) {
        return [[self.webView executeJSSynchronous:@"MyWallet.wallet.key(\"%@\").isWatchOnly", [address escapeStringForJS]] boolValue];
    } else {
        return NO;
    }
}

- (NSString*)labelForLegacyAddress:(NSString*)address
{
    if (![self isInitialized]) {
        return nil;
    }
    
    if ([self checkIfWalletHasAddress:address]) {
        return [self.webView executeJSSynchronous:@"MyWallet.wallet.key(\"%@\").label", [address escapeStringForJS]];
    } else {
        return nil;
    }
}

- (Boolean)isAddressArchived:(NSString *)address
{
    if (![self isInitialized] || !address) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.isArchived(\"%@\")", [address escapeStringForJS]] boolValue];
}

- (Boolean)isActiveAccountArchived:(int)account
{
    if (![self isInitialized]) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.isArchived(MyWalletPhone.getIndexOfActiveAccount(%d))", account] boolValue];
}

- (Boolean)isAccountArchived:(int)account
{
    if (![self isInitialized]) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.isArchived(%d)", account] boolValue];
}

- (BOOL)isBitcoinAddress:(NSString*)string
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.webView executeJSSynchronous:@"Helpers.isBitcoinAddress(\"%@\");", [string escapeStringForJS]] boolValue];
}

- (NSArray*)allLegacyAddresses
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString * allAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.wallet.addresses)"];
    
    return [allAddressesJSON getJSONObject];        
}

- (NSArray*)activeLegacyAddresses
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString *activeAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.wallet.activeAddresses)"];
    
    return [activeAddressesJSON getJSONObject];
}

- (NSArray*)spendableActiveLegacyAddresses
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString *spendableActiveAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.wallet.spendableActiveAddresses)"];
    
    return [spendableActiveAddressesJSON getJSONObject];
}

- (NSArray*)archivedLegacyAddresses
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString *activeAddressesJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWalletPhone.getLegacyArchivedAddresses())"];
    
    return [activeAddressesJSON getJSONObject];
}

- (void)setLabel:(NSString*)label forLegacyAddress:(NSString*)address
{
    if (![self isInitialized] || ![app checkInternetConnection]) {
        return;
    }
    
    self.isSyncing = YES;
    
    [self.webView executeJS:@"MyWalletPhone.setLabelForAddress(\"%@\", \"%@\")", [address escapeStringForJS], [label escapeStringForJS]];
}

- (void)toggleArchiveLegacyAddress:(NSString*)address
{
    if (![self isInitialized] || ![app checkInternetConnection]) {
        return;
    }
    
    self.isSyncing = YES;
    
    [self.webView executeJS:@"MyWalletPhone.toggleArchived(\"%@\")", [address escapeStringForJS]];
    
    [self getHistory];
}

- (void)toggleArchiveAccount:(int)account
{
    if (![self isInitialized] || ![app checkInternetConnection]) {
        return;
    }
    
    self.isSyncing = YES;
    
    [self.webView executeJS:@"MyWalletPhone.toggleArchived(%d)", account];
    
    [self getHistory];
}

- (void)archiveTransferredAddresses:(NSArray *)transferredAddresses
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.archiveTransferredAddresses(\"%@\")", [[transferredAddresses jsonString] escapeStringForJS]];
}

- (uint64_t)getLegacyAddressBalance:(NSString*)address
{
    uint64_t errorBalance = 0;
    if (![self isInitialized]) {
        return errorBalance;
    }
    
    if ([self checkIfWalletHasAddress:address]) {
        return [[self.webView executeJSSynchronous:@"MyWallet.wallet.key(\"%@\").balance", [address escapeStringForJS]] longLongValue];
    } else {
        DLog(@"Wallet error: Tried to get balance of address %@, which was not found in this wallet", address);
        return errorBalance;
    }
}

- (BOOL)addKey:(NSString*)privateKeyString
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.addKey(\"%@\")", [privateKeyString escapeStringForJS]] boolValue];
}

- (BOOL)addKey:(NSString*)privateKeyString toWatchOnlyAddress:(NSString *)watchOnlyAddress
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.addKeyToLegacyAddress(\"%@\", \"%@\")", [privateKeyString escapeStringForJS], [watchOnlyAddress escapeStringForJS]] boolValue];
}

- (void)sendFromWatchOnlyAddress:(NSString *)watchOnlyAddress privateKey:(NSString *)privateKeyString
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:[NSString stringWithFormat:@"MyWalletPhone.sendFromWatchOnlyAddressWithPrivateKey(\"%@\", \"%@\")", [privateKeyString escapeStringForJS], [watchOnlyAddress escapeStringForJS]]];
}

- (NSDictionary*)addressBook
{
    if (![self isInitialized]) {
        return [[NSDictionary alloc] init];
    }
    
    NSString * addressBookJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWallet.wallet.addressBook)"];
    
    return [addressBookJSON getJSONObject];
}

- (void)addToAddressBook:(NSString*)address label:(NSString*)label
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.addAddressBookEntry(\"%@\", \"%@\")", [address escapeStringForJS], [label escapeStringForJS]];
}

- (void)clearLocalStorage
{
    [self.webView executeJS:@"localStorage.clear();"];
}

- (NSString*)detectPrivateKeyFormat:(NSString*)privateKeyString
{
    if (![self isInitialized]) {
        return nil;
    }
    
   return [self.webView executeJSSynchronous:@"MyWalletPhone.detectPrivateKeyFormat(\"%@\")", [privateKeyString escapeStringForJS]];
}

- (void)createNewPayment
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.createNewPayment()"];
}

- (void)changePaymentFromAccount:(int)fromInt isAdvanced:(BOOL)isAdvanced
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.changePaymentFrom(%d, %d)", fromInt, isAdvanced];
}

- (void)changePaymentFromAddress:(NSString *)fromString isAdvanced:(BOOL)isAdvanced
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.changePaymentFrom(\"%@\", %d)", [fromString escapeStringForJS], isAdvanced];
}

- (void)changePaymentToAccount:(int)toInt
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.changePaymentTo(%d)", toInt];
}

- (void)changePaymentToAddress:(NSString *)toString
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.changePaymentTo(\"%@\")", [toString escapeStringForJS]];
}

- (void)changePaymentAmount:(uint64_t)amount
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.changePaymentAmount(%lld)", amount];
}

- (void)getInfoForTransferAllFundsToDefaultAccount
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.getInfoForTransferAllFundsToDefaultAccount()"];
}

- (void)setupFirstTransferForAllFundsToDefaultAccount:(NSString *)address secondPassword:(NSString *)secondPassword
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.transferAllFundsToDefaultAccount(true, \"%@\", \"%@\")", [address escapeStringForJS], [secondPassword escapeStringForJS]];
}

- (void)setupFollowingTransferForAllFundsToDefaultAccount:(NSString *)address secondPassword:(NSString *)secondPassword
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.transferAllFundsToDefaultAccount(false, \"%@\", \"%@\")", [address escapeStringForJS], [secondPassword escapeStringForJS]];
}

- (void)transferFundsToDefaultAccountFromAddress:(NSString *)address
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.transferFundsToDefaultAccountFromAddress(\"%@\")", [address escapeStringForJS]];
}

- (void)sweepPaymentRegular
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.sweepPaymentRegular()"];
}

- (void)sweepPaymentRegularThenConfirm
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.sweepPaymentRegularThenConfirm()"];
}

- (void)sweepPaymentAdvanced:(uint64_t)fee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.sweepPaymentAdvanced(%lld)", fee];
}

- (void)sweepPaymentAdvancedThenConfirm:(uint64_t)fee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.sweepPaymentAdvancedThenConfirm(%lld)", fee];
}

- (void)sweepPaymentThenConfirm:(BOOL)willConfirm isAdvanced:(BOOL)isAdvanced
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.sweepPaymentThenConfirm(%d, %d)", willConfirm, isAdvanced];
}

- (void)checkIfOverspending
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.checkIfUserIsOverSpending()"];
}

- (void)changeForcedFee:(uint64_t)fee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.changeForcedFee(%lld)", fee];
}

- (void)getFeeBounds:(uint64_t)fee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.getFeeBounds(%lld)", fee];
}

- (void)getTransactionFee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.getTransactionFee()"];
}

- (void)getSurgeStatus
{
    if (![self isInitialized]) {
        return;
    }
    
    return [self.webView executeJS:@"MyWalletPhone.getSurgeStatus()"];
}

- (uint64_t)dust
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.dust()"] longLongValue];
}

- (void)generateNewKey
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.generateNewAddress()"];
}

- (BOOL)checkIfWalletHasAddress:(NSString *)address
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.checkIfWalletHasAddress(\"%@\")", [address escapeStringForJS]] boolValue];
}

- (void)recoverWithEmail:(NSString *)email password:(NSString *)recoveryPassword passphrase:(NSString *)passphrase
{
    if (![self.webView isLoaded]) {
        return;
    }
    
    [self useDebugSettingsIfSet];
    
    self.emptyAccountIndex = 0;
    self.recoveredAccountIndex = 0;
    [self.webView executeJS:@"MyWalletPhone.recoverWithPassphrase(\"%@\",\"%@\",\"%@\")", [email escapeStringForJS], [recoveryPassword escapeStringForJS], [passphrase escapeStringForJS]];
}

- (void)resendTwoFactorSMS
{
    if ([self.webView isLoaded]) {
        [self.webView executeJS:@"MyWalletPhone.resendTwoFactorSms(\"%@\", \"%@\")", [self.guid escapeStringForJS], [self.sessionToken escapeStringForJS]];
    }
}

- (NSString *)get2FAType
{
    if ([self.webView isLoaded]) {
        return [self.webView executeJSSynchronous:@"MyWalletPhone.get2FAType()"];
    }
    return nil;
}

- (void)enableEmailNotifications
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.enableNotifications()"];
}

- (void)disableEmailNotifications
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.disableNotifications()"];
}

- (void)changeTorBlocking:(BOOL)willEnable
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.update_tor_ip_block(%d)", willEnable];
}

- (void)on_update_tor_success
{
    DLog(@"on_update_tor_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_TOR_BLOCKING_SUCCESS object:nil];
}

- (void)on_update_tor_error
{
    DLog(@"on_update_tor_error");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_TOR_BLOCKING_SUCCESS object:nil];
}
    
- (void)updateServerURL:(NSString *)newURL
{
    [self.webView executeJS:@"MyWalletPhone.updateServerURL(\"%@\")", [newURL escapeStringForJS]];
}

- (void)updateWebSocketURL:(NSString *)newURL
{
    [self.webView executeJS:@"MyWalletPhone.updateWebsocketURL(\"%@\")", [newURL escapeStringForJS]];
}

- (void)updateAPIURL:(NSString *)newURL
{
    [self.webView executeJS:@"MyWalletPhone.updateAPIURL(\"%@\")", [newURL escapeStringForJS]];
}

- (NSDictionary *)filteredWalletJSON
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString * filteredWalletJSON = [self.webView executeJSSynchronous:@"JSON.stringify(MyWalletPhone.filteredWalletJSON())"];
    
    return [filteredWalletJSON getJSONObject];
}

- (NSString *)getXpubForAccount:(int)accountIndex
{
    if (![self isInitialized]) {
        return nil;
    }
    
    return [self.webView executeJSSynchronous:@"MyWalletPhone.getXpubForAccount(%d)", accountIndex];
}

- (BOOL)isAccountNameValid:(NSString *)name
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.isAccountNameValid(\"%@\")", [name escapeStringForJS]] boolValue];
}

- (BOOL)isAddressAvailable:(NSString *)address
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.isAddressAvailable(\"%@\")", [address escapeStringForJS]] boolValue];
}

- (BOOL)isAccountAvailable:(int)account
{
    if (![self isInitialized]) {
        return NO;
    }

    return [[self.webView executeJSSynchronous:@"MyWalletPhone.isAccountAvailable(%d)", account] boolValue];
}

- (int)getIndexOfActiveAccount:(int)account
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.getIndexOfActiveAccount(%d)", account] intValue];
}

- (void)getSessionToken
{
    if (![self.webView isLoaded]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.getSessionToken()"];
}

# pragma mark - Transaction handlers

- (void)tx_on_start:(NSString*)txProgressID
{
    transactionProgressListeners *listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_start) {
            listener.on_start();
        }
    }
}

- (void)tx_on_begin_signing:(NSString*)txProgressID
{
    transactionProgressListeners *listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_begin_signing) {
            listener.on_begin_signing();
        }
    }
}

- (void)tx_on_sign_progress:(NSString*)txProgressID input:(NSString*)input
{
    transactionProgressListeners *listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_sign_progress) {
            listener.on_sign_progress([input intValue]);
        }
    }
}

- (void)tx_on_finish_signing:(NSString*)txProgressID
{
    transactionProgressListeners *listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_finish_signing) {
            listener.on_finish_signing();
        }
    }
}

- (void)tx_on_success:(NSString*)txProgressID secondPassword:(NSString *)secondPassword
{
    transactionProgressListeners *listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_success) {
            listener.on_success(secondPassword);
        }
    }
}

- (void)tx_on_error:(NSString*)txProgressID error:(NSString*)error secondPassword:(NSString *)secondPassword
{
    transactionProgressListeners *listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_error) {
            listener.on_error(error, secondPassword);
        }
    }
}

#pragma mark - Callbacks from JS to Obj-C dealing with loading texts

- (void)loading_start_download_wallet
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_DOWNLOADING_WALLET];
}

- (void)loading_start_decrypt_wallet
{
    [app updateBusyViewLoadingText:BC_STRING_LOADING_DECRYPTING_WALLET];
}

- (void)loading_start_build_wallet
{
    [app updateBusyViewLoadingText:BC_STRING_LOADING_LOADING_BUILD_HD_WALLET];
}

- (void)loading_start_multiaddr
{
    [app updateBusyViewLoadingText:BC_STRING_LOADING_LOADING_TRANSACTIONS];
}

- (void)loading_start_get_history
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_LOADING_TRANSACTIONS];
}

- (void)loading_start_get_wallet_and_history
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CHECKING_WALLET_UPDATES];
}

- (void)loading_start_upgrade_to_hd
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING_V3_WALLET];
}

- (void)loading_start_create_account
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING];
}

- (void)loading_start_new_account
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING_WALLET];
}

- (void)loading_start_create_new_address
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING_NEW_ADDRESS];
}

- (void)loading_start_generate_uuids
{
    [app updateBusyViewLoadingText:BC_STRING_LOADING_RECOVERY_CREATING_WALLET];
}

- (void)loading_start_recover_wallet
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_RECOVERING_WALLET];
}

- (void)loading_start_transfer_all:(NSNumber *)addressIndex
{
    [app showBusyViewWithLoadingText:[NSString stringWithFormat:BC_STRING_TRANSFER_ALL_CALCULATING_AMOUNTS_AND_FEES_ARGUMENT_OF_ARGUMENT, [addressIndex intValue], [[self spendableActiveLegacyAddresses] count]]];
}

- (void)loading_stop
{
    DLog(@"Stop loading");
    [app hideBusyView];
}

- (void)upgrade_success
{
    [app standardNotify:BC_STRING_UPGRADE_SUCCESS title:BC_STRING_UPGRADE_SUCCESS_TITLE delegate:nil];
    
    [app reloadTransactionFilterLabel];
}

#pragma mark - Callbacks from JS to Obj-C

- (void)log:(NSString*)message
{
    DLog(@"console.log: %@", [message description]);
}

- (void)ws_on_open
{
    DLog(@"ws_on_open");
}

- (void)ws_on_close
{
    DLog(@"ws_on_close");
}

- (void)on_fetch_needs_two_factor_code
{
    DLog(@"on_fetch_needs_two_factor_code");
    int twoFactorType = [[app.wallet get2FAType] intValue];
    if (twoFactorType == TWO_STEP_AUTH_TYPE_GOOGLE) {
        [app verifyTwoFactorGoogle];
    } else if (twoFactorType == TWO_STEP_AUTH_TYPE_SMS) {
        [app verifyTwoFactorSMS];
    } else if (twoFactorType == TWO_STEP_AUTH_TYPE_YUBI_KEY) {
        [app verifyTwoFactorYubiKey];
    } else {
        [app standardNotifyAutoDismissingController:BC_STRING_INVALID_AUTHENTICATION_TYPE];
    }
}

- (void)did_set_latest_block
{
    if (![self isInitialized]) {
        return;
    }
    
    DLog(@"did_set_latest_block");
    
    [self.webView executeJSWithCallback:^(NSString* latestBlockJSON) {
        
        [self parseLatestBlockJSON:latestBlockJSON];
        
    } command:@"JSON.stringify(MyWallet.wallet.latestBlock)"];
}

- (void)parseLatestBlockJSON:(NSString*)latestBlockJSON
{
    if ([latestBlockJSON isEqualToString:@"null"]) {
        return;
    }
    
    NSDictionary *dict = [latestBlockJSON getJSONObject];
    
    LatestBlock *latestBlock = [[LatestBlock alloc] init];
    
    latestBlock.height = [[dict objectForKey:@"height"] intValue];
    latestBlock.time = [[dict objectForKey:@"time"] longLongValue];
    latestBlock.blockIndex = [[dict objectForKey:@"block_index"] intValue];
    
    [delegate didSetLatestBlock:latestBlock];
}

- (void)reloadFilter
{
    [self did_multiaddr];
}

- (void)did_multiaddr
{
    if (![self isInitialized]) {
        return;
    }
    
    DLog(@"did_multiaddr");
    
    [self getFinalBalance];
    
    NSString *filter = @"";
#ifdef ENABLE_TRANSACTION_FILTERING
    int filterIndex = (int)app.transactionsViewController.filterIndex;

    if (filterIndex == FILTER_INDEX_ALL) {
        filter = @"";
    } else if (filterIndex == FILTER_INDEX_IMPORTED_ADDRESSES) {
        filter = TRANSACTION_FILTER_IMPORTED;
    } else {
        filter = [NSString stringWithFormat:@"%d", filterIndex];
    }
#endif
    [self.webView executeJSWithCallback:^(NSString * multiAddrJSON) {
        MultiAddressResponse *response = [self parseMultiAddrJSON:multiAddrJSON];

        if (!self.isSyncing) {
            [self loading_stop];
        }
        
        [delegate didGetMultiAddressResponse:response];
        
    } command:[NSString stringWithFormat:@"JSON.stringify(MyWalletPhone.getMultiAddrResponse(\"%@\"))", filter]];
}

- (MultiAddressResponse *)parseMultiAddrJSON:(NSString*)multiAddrJSON
{
    if (multiAddrJSON == nil)
        return nil;
    
    NSDictionary *dict = [multiAddrJSON getJSONObject];
    
    MultiAddressResponse *response = [[MultiAddressResponse alloc] init];
        
    response.final_balance = [[dict objectForKey:DICTIONARY_KEY_MULTIADDRESS_FINAL_BALANCE] longLongValue];
    response.total_received = [[dict objectForKey:DICTIONARY_KEY_MULTIADDRESS_TOTAL_RECEIVED] longLongValue];
    response.n_transactions = [[dict objectForKey:DICTIONARY_KEY_MULTIADDRESS_NUMBER_TRANSACTIONS] unsignedIntValue];
    response.total_sent = [[dict objectForKey:DICTIONARY_KEY_MULTIADDRESS_TOTAL_SENT] longLongValue];
    response.addresses = [dict objectForKey:DICTIONARY_KEY_MULTIADDRESS_ADDRESSES];
    response.transactions = [NSMutableArray array];
    
    NSArray *transactionsArray = [dict objectForKey:DICTIONARY_KEY_MULTIADDRESS_TRANSACTIONS];
    
    for (NSDictionary *dict in transactionsArray) {
        Transaction *tx = [Transaction fromJSONDict:dict];
        
        [response.transactions addObject:tx];
    }
    
    {
        NSDictionary *symbolLocalDict = [dict objectForKey:DICTIONARY_KEY_MULTIADDRESS_SYMBOL_LOCAL] ;
        if (symbolLocalDict) {
            response.symbol_local = [CurrencySymbol symbolFromDict:symbolLocalDict];
        }
    }
    
    {
        NSDictionary *symbolBTCDict = [dict objectForKey:DICTIONARY_KEY_MULTIADDRESS_SYMBOL_BTC] ;
        if (symbolBTCDict) {
            response.symbol_btc = [CurrencySymbol symbolFromDict:symbolBTCDict];
        }
    }
    
    return response;
}

- (void)on_tx_received
{
    DLog(@"on_tx_received");
    
    self.didReceiveMessageForLastTransaction = YES;

    [app playBeepSound];
    
    [app.transactionsViewController animateNextCellAfterReload];
}

- (void)getPrivateKeyPassword:(NSString *)canDiscard success:(void(^)(id))_success error:(void(^)(id))_error
{
    [app getPrivateKeyPassword:^(NSString *privateKeyPassword) {
        _success(privateKeyPassword);
    } error:_error];
}

- (void)getSecondPassword:(NSString *)canDiscard success:(void(^)(id))_success error:(void(^)(id))_error
{
    [app getSecondPassword:^(NSString *secondPassword) {
        _success(secondPassword);
    } error:_error];
}

- (void)setLoadingText:(NSString*)message
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_LOADING_TEXT object:message];
}

- (void)makeNotice:(NSString*)type id:(NSString*)_id message:(NSString*)message
{
    // This is kind of ugly. When the wallet fails to load, usually because of a connection problem, wallet.js throws two errors in the setGUID function and we only want to show one. This filters out the one we don't want to show.
    if ([message isEqualToString:@"Error changing wallet identifier"]) {
        return;
    }
    
    // Don't display an error message for this notice, instead show a note in the sideMenu
    if ([message isEqualToString:@"For Improved security add an email address to your account."]) {        
        return;
    }
    
    NSRange invalidEmailStringRange = [message rangeOfString:@"update-email-error" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (invalidEmailStringRange.location != NSNotFound) {
        [self performSelector:@selector(on_update_email_error) withObject:nil afterDelay:DELAY_KEYBOARD_DISMISSAL];
        return;
    }
    
    NSRange updateCurrencyErrorStringRange = [message rangeOfString:@"currency-error" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (updateCurrencyErrorStringRange.location != NSNotFound) {
        [self performSelector:@selector(on_change_currency_error) withObject:nil afterDelay:0.1f];
        return;
    }
    
    NSRange updateSMSErrorStringRange = [message rangeOfString:@"sms-error" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (updateSMSErrorStringRange.location != NSNotFound) {
        [self performSelector:@selector(on_change_mobile_number_error) withObject:nil afterDelay:0.1f];
        return;
    }
    
    NSRange updatePasswordHintErrorStringRange = [message rangeOfString:@"password-hint1-error" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (updatePasswordHintErrorStringRange.location != NSNotFound) {
        [self performSelector:@selector(on_update_password_hint_error) withObject:nil afterDelay:0.1f];
        return;
    }
    
    NSRange incorrectPasswordErrorStringRange = [message rangeOfString:@"please check that your password is correct" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (incorrectPasswordErrorStringRange.location != NSNotFound && ![app guid]) {
        // Error message shown in error_other_decrypting_wallet without guid
        return;
    }
    
    NSRange errorSavingWalletStringRange = [message rangeOfString:@"Error Saving Wallet" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (errorSavingWalletStringRange.location != NSNotFound) {
        [app standardNotify:BC_STRING_ERROR_SAVING_WALLET_CHECK_FOR_OTHER_DEVICES];
        return;
    }
    
    if ([type isEqualToString:@"error"]) {
        [app standardNotify:message title:BC_STRING_ERROR delegate:nil];
    } else if ([type isEqualToString:@"info"]) {
        [app standardNotify:message title:BC_STRING_INFORMATION delegate:nil];
    }
}

- (void)error_other_decrypting_wallet:(NSString *)message
{
    DLog(@"error_other_decrypting_wallet");
    
    // This error message covers the case where the GUID is 36 characters long but is not valid. This can only be checked after JS has been loaded. To avoid multiple error messages, it finds a localized "identifier" substring in the error description. Currently, different manual pairing error messages are sent to both my-wallet.js and wallet-ios.js (in this case, also to the same error callback), so a cleaner approach that avoids a substring search would either require more distinguishable error callbacks (separated by scope) or thorough refactoring.
    
    if (message != nil) {
        NSRange identifierRange = [message rangeOfString:BC_STRING_IDENTIFIER options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
        NSRange connectivityErrorRange = [message rangeOfString:ERROR_FAILED_NETWORK_REQUEST options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
        if (identifierRange.location != NSNotFound) {
            [app standardNotify:message title:BC_STRING_ERROR delegate:nil];
            [self error_restoring_wallet];
            return;
        } else if (connectivityErrorRange.location != NSNotFound) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION_LONG * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [app standardNotify:BC_STRING_REQUEST_FAILED_PLEASE_CHECK_INTERNET_CONNECTION title:BC_STRING_ERROR delegate:nil];
            });
            [self error_restoring_wallet];
            return;
        }
        
        if (![app guid]) {
            // This error is used whe trying to login with incorrect passwords or when the account is locked, so present an alert if the app has no guid, since it currently conflicts with makeNotice when backgrounding after changing password in-app
            [app standardNotifyAutoDismissingController:message];
        }
    }
}

- (void)error_restoring_wallet
{
    DLog(@"error_restoring_wallet");
    if ([delegate respondsToSelector:@selector(walletFailedToDecrypt)])
        [delegate walletFailedToDecrypt];
}

- (void)did_decrypt
{
    DLog(@"did_decrypt");
    
    if (self.didPairAutomatically) {
        self.didPairAutomatically = NO;
        [app standardNotify:[NSString stringWithFormat:BC_STRING_WALLET_PAIRED_SUCCESSFULLY_DETAIL] title:BC_STRING_WALLET_PAIRED_SUCCESSFULLY_TITLE delegate:nil];
    }
    
    self.sharedKey = [self.webView executeJSSynchronous:@"MyWallet.wallet.sharedKey"];
    self.guid = [self.webView executeJSSynchronous:@"MyWallet.wallet.guid"];

    if ([delegate respondsToSelector:@selector(walletDidDecrypt)])
        [delegate walletDidDecrypt];
}

- (void)did_load_wallet
{
    DLog(@"did_load_wallet");

    if (self.isNew) {
        
        NSString *currencyCode = [[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode];
        
        if ([[self.currencySymbols allKeys] containsObject:currencyCode]) {
            [self changeLocalCurrency:[[NSLocale currentLocale] objectForKey:NSLocaleCurrencyCode]];
        }
    }
    
    self.isNew = NO;
    
    if ([delegate respondsToSelector:@selector(walletDidFinishLoad)])
        [delegate walletDidFinishLoad];
}

- (void)on_create_new_account:(NSString*)_guid sharedKey:(NSString*)_sharedKey password:(NSString*)_password
{
    DLog(@"on_create_new_account:");
    
    if ([delegate respondsToSelector:@selector(didCreateNewAccount:sharedKey:password:)])
        [delegate didCreateNewAccount:_guid sharedKey:_sharedKey password:_password];
}

- (void)on_add_private_key_start
{
    DLog(@"on_add_private_key_start");
    self.isSyncing = YES;

    [app showBusyViewWithLoadingText:BC_STRING_LOADING_IMPORT_KEY];
}

- (void)on_add_key:(NSString*)address
{
    DLog(@"on_add_private_key");
    self.isSyncing = YES;

    if ([delegate respondsToSelector:@selector(didImportKey:)]) {
        [delegate didImportKey:address];
    }
}

- (void)on_add_incorrect_private_key:(NSString *)address
{
    DLog(@"on_add_incorrect_private_key:");
    self.isSyncing = YES;
    
    if ([delegate respondsToSelector:@selector(didImportIncorrectPrivateKey:)]) {
        [delegate didImportIncorrectPrivateKey:address];
    }
}

- (void)on_add_private_key_to_legacy_address
{
    DLog(@"on_add_private_key_to_legacy_address:");
    self.isSyncing = YES;
    
    if ([delegate respondsToSelector:@selector(didImportPrivateKeyToLegacyAddress)]) {
        [delegate didImportPrivateKeyToLegacyAddress];
    }
}

- (void)on_error_adding_private_key:(NSString*)error
{
    if ([delegate respondsToSelector:@selector(didFailToImportPrivateKey:)]) {
        [delegate didFailToImportPrivateKey:error];
    }
}

- (void)on_error_adding_private_key_watch_only:(NSString*)error
{
    if ([delegate respondsToSelector:@selector(didFailToImportPrivateKeyForWatchOnlyAddress:)]) {
        [delegate didFailToImportPrivateKeyForWatchOnlyAddress:error];
    }
}

- (void)on_error_creating_new_account:(NSString*)message
{
    DLog(@"on_error_creating_new_account:");
    
    if ([delegate respondsToSelector:@selector(errorCreatingNewAccount:)])
        [delegate errorCreatingNewAccount:message];
}

- (void)on_error_pin_code_put_error:(NSString*)message
{
    DLog(@"on_error_pin_code_put_error:");
    
    if ([delegate respondsToSelector:@selector(didFailPutPin:)])
        [delegate didFailPutPin:message];
}

- (void)on_pin_code_put_response:(NSDictionary*)responseObject
{
    DLog(@"on_pin_code_put_response: %@", responseObject);
    
    if ([delegate respondsToSelector:@selector(didPutPinSuccess:)])
        [delegate didPutPinSuccess:responseObject];
}

- (void)on_error_pin_code_get_timeout
{
    DLog(@"on_error_pin_code_get_timeout");
    
    if ([delegate respondsToSelector:@selector(didFailGetPinTimeout)])
    [delegate didFailGetPinTimeout];
}

- (void)on_error_pin_code_get_empty_response
{
    DLog(@"on_error_pin_code_get_empty_response");
    
    if ([delegate respondsToSelector:@selector(didFailGetPinNoResponse)])
    [delegate didFailGetPinNoResponse];
}

- (void)on_error_pin_code_get_invalid_response
{
    DLog(@"on_error_pin_code_get_invalid_response");
    
    if ([delegate respondsToSelector:@selector(didFailGetPinInvalidResponse)])
    [delegate didFailGetPinInvalidResponse];
}

- (void)on_pin_code_get_response:(NSDictionary*)responseObject
{
    DLog(@"on_pin_code_get_response:");
    
    if ([delegate respondsToSelector:@selector(didGetPinResponse:)])
        [delegate didGetPinResponse:responseObject];
}

- (void)on_error_maintenance_mode
{
    DLog(@"on_error_maintenance_mode");
    [self loading_stop];
    [app.pinEntryViewController reset];
    [app standardNotify:BC_STRING_MAINTENANCE_MODE];
}

- (void)on_backup_wallet_start
{
    DLog(@"on_backup_wallet_start");
}

- (void)on_backup_wallet_error
{
    DLog(@"on_backup_wallet_error");
    
    if ([delegate respondsToSelector:@selector(didFailBackupWallet)])
        [delegate didFailBackupWallet];
}

- (void)on_backup_wallet_success
{
    DLog(@"on_backup_wallet_success");
    if ([delegate respondsToSelector:@selector(didBackupWallet)])
        [delegate didBackupWallet];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
    // Hide the busy view if previously syncing
    [self loading_stop];
    self.isSyncing = NO;
}

- (void)did_fail_set_guid
{
    DLog(@"did_fail_set_guid");
    
    if ([delegate respondsToSelector:@selector(walletFailedToLoad)])
        [delegate walletFailedToLoad];
}

- (void)on_change_local_currency_success
{
    DLog(@"on_change_local_currency_success");
    [self getHistory];
}

- (void)on_change_currency_error
{
    DLog(@"on_change_local_currency_error");
    [app standardNotify:BC_STRING_SETTINGS_ERROR_LOADING_MESSAGE title:BC_STRING_SETTINGS_ERROR_UPDATING_TITLE delegate:nil];
}

- (void)on_get_account_info_success:(NSString *)accountInfo
{
    DLog(@"on_get_account_info");
    self.accountInfo = [accountInfo getJSONObject];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
}

- (void)on_get_all_currency_symbols_success:(NSString *)currencies
{
    DLog(@"on_get_all_currency_symbols_success");
    NSDictionary *allCurrencySymbolsDictionary = [currencies getJSONObject];
    self.currencySymbols = allCurrencySymbolsDictionary;
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_GET_ALL_CURRENCY_SYMBOLS_SUCCESS object:nil];
}

- (void)on_change_email_success
{
    DLog(@"on_change_email_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_EMAIL_SUCCESS object:nil];
}

- (void)on_resend_verification_email_success
{
    DLog(@"on_resend_verification_email_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_RESEND_VERIFICATION_EMAIL_SUCCESS object:nil];
}

- (void)on_change_mobile_number_success
{
    DLog(@"on_change_mobile_number_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_SUCCESS object:nil];
}

- (void)on_change_mobile_number_error
{
    DLog(@"on_change_mobile_number_error");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_MOBILE_NUMBER_ERROR object:nil];
}

- (void)on_verify_mobile_number_success
{
    DLog(@"on_verify_mobile_number_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_VERIFY_MOBILE_NUMBER_SUCCESS object:nil];
}

- (void)on_verify_mobile_number_error
{
    DLog(@"on_verify_mobile_number_error");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_VERIFY_MOBILE_NUMBER_ERROR object:nil];
}

- (void)on_change_two_step_success
{
    DLog(@"on_change_two_step_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_TWO_STEP_SUCCESS object:nil];
}

- (void)on_change_two_step_error
{
    DLog(@"on_change_two_step_error");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_TWO_STEP_ERROR object:nil];
}

- (void)on_update_password_hint_success
{
    DLog(@"on_update_password_hint_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_PASSWORD_HINT_SUCCESS object:nil];
}

- (void)on_update_password_hint_error
{
    DLog(@"on_update_password_hint_error");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_PASSWORD_HINT_ERROR object:nil];
}

- (void)on_change_password_success
{
    DLog(@"on_change_password_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_PASSWORD_SUCCESS object:nil];
}

- (void)on_change_password_error
{
    DLog(@"on_change_password_error");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_PASSWORD_ERROR object:nil];
}

- (void)on_get_history_success
{
    DLog(@"on_get_history_success");
    
    // Keep showing busy view to prevent user input while archiving/unarchiving addresses
    if (!self.isSyncing) {
        [self loading_stop];
    }
}

- (void)did_get_fee:(NSNumber *)fee dust:(NSNumber *)dust
{
    DLog(@"update_fee");
    DLog(@"Wallet: fee is %@", fee);
    if ([self.delegate respondsToSelector:@selector(didGetFee:dust:)]) {
        [self.delegate didGetFee:fee dust:dust];
    }
}

- (void)did_change_forced_fee:(NSNumber *)fee dust:(NSNumber *)dust
{
    DLog(@"did_change_forced_fee");
    if ([self.delegate respondsToSelector:@selector(didChangeForcedFee:dust:)]) {
        [self.delegate didChangeForcedFee:fee dust:dust];
    }
}

- (void)update_fee_bounds:(NSArray *)bounds confirmationEstimation:(NSNumber *)confirmationEstimation maxAmounts:(NSArray *)maxAmounts maxFees:(NSArray *)maxFees
{    
    DLog(@"update_fee_bounds:confirmationEstimation:maxAmounts:maxFees");
    
    if ([self.delegate respondsToSelector:@selector(didGetFeeBounds:confirmationEstimation:maxAmounts:maxFees:)]) {
        [self.delegate didGetFeeBounds:bounds confirmationEstimation:confirmationEstimation maxAmounts:maxAmounts maxFees:maxFees];
    }
}

- (void)update_surge_status:(NSNumber *)surgeStatus
{
    DLog(@"update_surge_status");
    if ([self.delegate respondsToSelector:@selector(didGetSurgeStatus:)]) {
        [self.delegate didGetSurgeStatus:[surgeStatus boolValue]];
    }
}

- (void)update_max_amount:(NSNumber *)amount fee:(NSNumber *)fee dust:(NSNumber *)dust willConfirm:(NSNumber *)willConfirm
{
    DLog(@"update_max_amount");
    DLog(@"Wallet: max amount is %@ with fee %@", amount, fee);
    
    if ([self.delegate respondsToSelector:@selector(didGetMaxFee:amount:dust:willConfirm:)]) {
        [self.delegate didGetMaxFee:fee amount:amount dust:dust willConfirm:[willConfirm boolValue]];
    }
}

- (void)check_max_amount:(NSNumber *)amount fee:(NSNumber *)fee
{
    DLog(@"check_max_amount");
    if ([self.delegate respondsToSelector:@selector(didCheckForOverSpending:fee:)]) {
        [self.delegate didCheckForOverSpending:amount fee:fee];
    }
}

- (void)on_error_update_fee:(NSDictionary *)error
{
    DLog(@"on_error_update_fee");
    
    NSString *message = error[DICTIONARY_KEY_MESSAGE][DICTIONARY_KEY_ERROR];
    if ([message isEqualToString:ERROR_NO_UNSPENT_OUTPUTS] || [message isEqualToString:ERROR_AMOUNTS_ADDRESSES_MUST_EQUAL]) {
        [app standardNotifyAutoDismissingController:BC_STRING_NO_AVAILABLE_FUNDS];
    } else if ([message isEqualToString:ERROR_BELOW_DUST_THRESHOLD]) {
        uint64_t threshold = [error[DICTIONARY_KEY_MESSAGE][DICTIONARY_KEY_THRESHOLD] longLongValue];
        [app standardNotifyAutoDismissingController:[NSString stringWithFormat:BC_STRING_MUST_BE_ABOVE_OR_EQUAL_TO_DUST_THRESHOLD, threshold]];
    } else if ([message isEqualToString:ERROR_FETCH_UNSPENT]) {
        [app standardNotifyAutoDismissingController:BC_STRING_SOMETHING_WENT_WRONG_CHECK_INTERNET_CONNECTION];
    } else {
        [app standardNotifyAutoDismissingController:message];
    }
    
    if ([self.delegate respondsToSelector:@selector(enableSendPaymentButtons)]) {
        [self.delegate enableSendPaymentButtons];
    }
}

- (void)on_payment_notice:(NSString *)notice
{
    if (app.tabViewController.selectedIndex == TAB_SEND) {
        [app standardNotifyAutoDismissingController:notice title:BC_STRING_INFORMATION];
    }
}

- (void)on_generate_key
{
    DLog(@"on_generate_key");
    [delegate didGenerateNewAddress];
}

- (void)on_error_generating_new_address:(NSString*)error
{
    DLog(@"on_error_generating_new_address");
    [app standardNotify:error];
}

- (void)on_add_new_account
{
    DLog(@"on_add_new_account");
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
}

- (void)on_error_add_new_account:(NSString*)error
{
    DLog(@"on_error_generating_new_address");
    [app standardNotify:error];
}

- (void)on_success_get_recovery_phrase:(NSString*)phrase
{
    DLog(@"on_success_get_recovery_phrase:");
    self.recoveryPhrase = phrase;
}

- (void)on_success_recover_with_passphrase:(NSDictionary *)recoveredWalletDictionary
{
    DLog(@"on_recover_with_passphrase_success_guid:sharedKey:password:");
    
    if ([delegate respondsToSelector:@selector(didRecoverWallet)])
        [delegate didRecoverWallet];
    
    [self loadWalletWithGuid:recoveredWalletDictionary[@"guid"] sharedKey:recoveredWalletDictionary[@"sharedKey"] password:recoveredWalletDictionary[@"password"]];
}

- (void)on_error_recover_with_passphrase:(NSString *)error
{
    DLog(@"on_error_recover_with_passphrase:");
    [self loading_stop];
    if (!error) {
        [app standardNotifyAutoDismissingController:BC_STRING_INVALID_RECOVERY_PHRASE];
    } else if ([error isEqualToString:@""]) {
        [app standardNotifyAutoDismissingController:BC_STRING_NO_INTERNET_CONNECTION];
    } else if ([error isEqualToString:ERROR_TIMEOUT_REQUEST]){
        [app standardNotifyAutoDismissingController:BC_STRING_TIMED_OUT];
    } else {
        [app standardNotifyAutoDismissingController:error];
    }
    if ([delegate respondsToSelector:@selector(didFailRecovery)])
        [delegate didFailRecovery];
}

- (void)on_progress_recover_with_passphrase:(NSString *)totalReceived finalBalance:(NSString *)finalBalance
{
    uint64_t fundsInAccount = [finalBalance longLongValue];
    
    if ([totalReceived longLongValue] == 0) {
        self.emptyAccountIndex++;
        [app updateBusyViewLoadingText:[NSString stringWithFormat:BC_STRING_LOADING_RECOVERING_WALLET_CHECKING_ARGUMENT_OF_ARGUMENT, self.emptyAccountIndex, self.emptyAccountIndex > RECOVERY_ACCOUNT_DEFAULT_NUMBER ? self.emptyAccountIndex : RECOVERY_ACCOUNT_DEFAULT_NUMBER]];
    } else {
        self.emptyAccountIndex = 0;
        self.recoveredAccountIndex++;
        [app updateBusyViewLoadingText:[NSString stringWithFormat:BC_STRING_LOADING_RECOVERING_WALLET_ARGUMENT_FUNDS_ARGUMENT, self.recoveredAccountIndex, [app formatMoney:fundsInAccount]]];
    }
}

- (void)on_error_downloading_account_settings
{
    DLog(@"on_error_downloading_account_settings");
    [app standardNotify:BC_STRING_SETTINGS_ERROR_LOADING_MESSAGE title:BC_STRING_SETTINGS_ERROR_LOADING_TITLE delegate:nil];
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:USER_DEFAULTS_KEY_LOADED_SETTINGS];
}

- (void)on_update_email_error
{
    [app standardNotify:BC_STRING_INVALID_EMAIL_ADDRESS title:BC_STRING_ERROR delegate:nil];
}

- (void)on_error_get_history:(NSString *)error
{
    [self loading_stop];
    if ([self.delegate respondsToSelector:@selector(didFailGetHistory:)]) {
        [self.delegate didFailGetHistory:error];
    }
}

- (void)on_resend_two_factor_sms_success
{
    [app verifyTwoFactorSMS];
}

- (void)on_resend_two_factor_sms_error:(NSString *)error
{
    [app standardNotifyAutoDismissingController:error];
}

- (void)wrong_two_factor_code
{
    self.twoFactorInput = nil;
    [app standardNotifyAutoDismissingController:BC_STRING_SETTINGS_VERIFY_INVALID_CODE];
}

- (void)on_change_email_notifications_success
{
    DLog(@"on_change_email_notifications_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_EMAIL_NOTIFICATIONS_SUCCESS object:nil];
}

- (void)on_change_email_notifications_error
{
    DLog(@"on_change_email_notifications_error");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_EMAIL_NOTIFICATIONS_ERROR object:nil];
}

- (void)return_to_addresses_screen
{
    DLog(@"return_to_addresses_screen");
    if ([self.delegate respondsToSelector:@selector(returnToAddressesScreen)]) {
        [self.delegate returnToAddressesScreen];
    }
}

- (void)on_error_account_name_in_use
{
    DLog(@"on_error_account_name_in_use");
    if ([self.delegate respondsToSelector:@selector(alertUserOfInvalidAccountName)]) {
        [self.delegate alertUserOfInvalidAccountName];
    }
}

- (void)on_success_import_key_for_sending_from_watch_only
{
    [self loading_stop];
    
    DLog(@"on_success_import_key_for_sending_from_watch_only");
    if ([self.delegate respondsToSelector:@selector(sendFromWatchOnlyAddress)]) {
        [self.delegate sendFromWatchOnlyAddress];
    }
}

- (void)on_error_import_key_for_sending_from_watch_only:(NSString *)error
{
    [self loading_stop];
    
    DLog(@"on_error_import_key_for_sending_from_watch_only");
    if ([error isEqualToString:ERROR_WRONG_PRIVATE_KEY]) {
        if ([self.delegate respondsToSelector:@selector(alertUserOfInvalidPrivateKey)]) {
            [self.delegate alertUserOfInvalidPrivateKey];
        }
    } else if ([error isEqualToString:ERROR_WRONG_BIP_PASSWORD]) {
        [app standardNotifyAutoDismissingController:BC_STRING_WRONG_BIP38_PASSWORD];
    } else {
        [app standardNotifyAutoDismissingController:error];
    }
}

- (void)update_send_balance:(NSNumber *)balance
{
    DLog(@"update_send_balance");
    if ([self.delegate respondsToSelector:@selector(updateSendBalance:)]) {
        [self.delegate updateSendBalance:balance];
    }
}

- (void)update_transfer_all_amount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed
{
    DLog(@"update_transfer_all_amount:fee:");
    
    if ([self.delegate respondsToSelector:@selector(updateTransferAllAmount:fee:addressesUsed:)]) {
        [self.delegate updateTransferAllAmount:amount fee:fee addressesUsed:addressesUsed];
    }
}

- (void)on_error_transfer_all:(NSString *)error secondPassword:(NSString *)secondPassword
{
    DLog(@"on_error_transfer_all");
    if ([self.delegate respondsToSelector:@selector(didErrorDuringTransferAll:secondPassword:)]) {
        [self.delegate didErrorDuringTransferAll:error secondPassword:secondPassword];
    }
}

- (void)show_summary_for_transfer_all
{
    DLog(@"show_summary_for_transfer_all");
    if ([self.delegate respondsToSelector:@selector(showSummaryForTransferAll)]) {
        [self.delegate showSummaryForTransferAll];
    }
}

- (void)send_transfer_all:(NSString *)secondPassword
{
    DLog(@"send_transfer_all");
    if ([self.delegate respondsToSelector:@selector(sendDuringTransferAll:)]) {
        [self.delegate sendDuringTransferAll:secondPassword];
    }
}

- (void)update_loaded_all_transactions:(NSNumber *)loadedAll
{
    DLog(@"loaded_all_transactions");
    
    if ([self.delegate respondsToSelector:@selector(updateLoadedAllTransactions:)]) {
        [self.delegate updateLoadedAllTransactions:loadedAll];
    }
}

- (void)on_get_session_token:(NSString *)token
{
    DLog(@"on_get_session_token:");
    self.sessionToken = token;
}

- (void)show_email_authorization_alert
{
    DLog(@"show_email_authorization_alert");
    [app standardNotifyAutoDismissingController:BC_STRING_MANUAL_PAIRING_AUTHORIZATION_REQUIRED_MESSAGE title:BC_STRING_MANUAL_PAIRING_AUTHORIZATION_REQUIRED_TITLE];
}

# pragma mark - Calls from Obj-C to JS for HD wallet

- (void)upgradeToV3Wallet
{
    if (![self isInitialized]) {
        return;
    }
    
    DLog(@"Creating HD Wallet");
    [self.webView executeJS:@"MyWalletPhone.upgradeToV3(\"%@\");", NSLocalizedString(@"My Bitcoin Wallet", nil)];
}

- (Boolean)hasAccount
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.isUpgradedToHD"] boolValue];
}

- (Boolean)didUpgradeToHd
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.isUpgradedToHD"] boolValue];
}

- (void)getRecoveryPhrase:(NSString *)secondPassword;
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJSSynchronous:@"MyWalletPhone.getRecoveryPhrase(\"%@\")", [secondPassword escapeStringForJS]];
}

- (BOOL)isRecoveryPhraseVerified {
    if (![self isInitialized]) {
        return NO;
    }
    
    if (![self didUpgradeToHd]) {
        return NO;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.hdwallet.isMnemonicVerified"] boolValue];
}

- (void)markRecoveryPhraseVerified
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJSSynchronous:@"MyWallet.wallet.hdwallet.verifyMnemonic()"];
}

- (int)getActiveAccountsCount
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.getActiveAccountsCount()"] intValue];
}

- (int)getAllAccountsCount
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.getAllAccountsCount()"] intValue];
}

- (int)getDefaultAccountIndex
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.getDefaultAccountIndex()"] intValue];
}

- (void)setDefaultAccount:(int)index
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJSSynchronous:@"MyWalletPhone.setDefaultAccount(%d)", index];
}

- (BOOL)hasLegacyAddresses
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.addresses.length > 0"] boolValue];
}

- (uint64_t)getTotalActiveBalance
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.balanceActive"] longLongValue];
}

- (uint64_t)getTotalBalanceForActiveLegacyAddresses
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.balanceActiveLegacy"] longLongValue];
}

- (uint64_t)getTotalBalanceForSpendableActiveLegacyAddresses
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.balanceSpendableActiveLegacy"] longLongValue];
}

- (uint64_t)getBalanceForAccount:(int)account
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.getBalanceForAccount(%d)", account] longLongValue];
}

- (NSString *)getLabelForAccount:(int)account
{
    if (![self isInitialized]) {
        return nil;
    }
    
    return [self.webView executeJSSynchronous:@"MyWalletPhone.getLabelForAccount(%d)", account];
}

- (void)setLabelForAccount:(int)account label:(NSString *)label
{
    if ([self isInitialized] && [app checkInternetConnection]) {
        self.isSyncing = YES;
        [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
        
        [self.webView executeJSSynchronous:@"MyWalletPhone.setLabelForAccount(%d, \"%@\")", account, [label escapeStringForJS]];
    }
}

- (void)createAccountWithLabel:(NSString *)label
{
    if ([self isInitialized] && [app checkInternetConnection]) {
        // Show loading text
        [self loading_start_create_account];
        
        self.isSyncing = YES;
        
        // Wait a little bit to make sure the loading text is showing - then execute the blocking and kind of long create account
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.webView executeJSSynchronous:@"MyWalletPhone.createAccount(\"%@\")", [label escapeStringForJS]];
        });
    }
}

- (NSString *)getReceiveAddressForAccount:(int)account
{
    if (![self isInitialized]) {
        return nil;
    }
    
    return [self.webView executeJSSynchronous:@"MyWalletPhone.getReceivingAddressForAccount(%d)", account];
}

- (void)setPbkdf2Iterations:(int)iterations
{
    DLog(@"Setting PBKDF2 Iterations");
    
    [self.webView executeJSSynchronous:@"MyWalletPhone.setPbkdf2Iterations(%d)", iterations];
}

#pragma mark - Callbacks from JS to Obj-C for HD wallet

- (void)reload
{
    DLog(@"reload");
    
    [app reload];
}

- (void)logging_out
{
    DLog(@"logging_out");
    
    [app logoutAndShowPasswordModal];
}

#pragma mark - Callbacks from javascript localstorage

- (void)getKey:(NSString*)key success:(void (^)(NSString*))success 
{
    id value = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    
    DLog(@"getKey:%@", key);
    
    success(value);
}

- (void)saveKey:(NSString*)key value:(NSString*)value 
{
    DLog(@"saveKey:%@", key);

    [[NSUserDefaults standardUserDefaults] setValue:value forKey:key];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)removeKey:(NSString*)key 
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)clearKeys 
{
    NSString * appDomain = [[NSBundle mainBundle] bundleIdentifier];
    
    [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:appDomain];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

# pragma mark - Cyrpto helpers, called from JS

- (void)crypto_scrypt:(id)_password salt:(id)salt n:(NSNumber*)N r:(NSNumber*)r p:(NSNumber*)p dkLen:(NSNumber*)derivedKeyLen success:(void(^)(id))_success error:(void(^)(id))_error
{
    [app showBusyViewWithLoadingText:BC_STRING_DECRYPTING_PRIVATE_KEY];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [self _internal_crypto_scrypt:_password salt:salt n:[N unsignedLongLongValue] r:[r unsignedIntegerValue] p:[p unsignedIntegerValue] dkLen:[derivedKeyLen unsignedIntegerValue]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                _success([data hexadecimalString]);
            } else {
                [app hideBusyView];

                _error(@"Scrypt Error");
            }
        });
    });
}

- (NSData*)_internal_crypto_scrypt:(id)_password salt:(id)_salt n:(uint64_t)N r:(uint32_t)r p:(uint32_t)p dkLen:(uint32_t)derivedKeyLen
{    
    uint8_t * _passwordBuff = NULL;
    size_t _passwordBuffLen = 0;
    if ([_password isKindOfClass:[NSArray class]]) {
        _passwordBuff = alloca([_password count]);
        _passwordBuffLen = [_password count];
        
        {
            int ii = 0;
            for (NSNumber * number in _password) {
                _passwordBuff[ii] = [number shortValue];
                ++ii;
            }
        }
    } else if ([_password isKindOfClass:[NSString class]]) {
         _passwordBuff = (uint8_t*)[_password UTF8String];
        _passwordBuffLen = [_password length];
    } else {
        DLog(@"Scrypt password unsupported type");
        return nil;
    }
    
    uint8_t * _saltBuff = NULL;
    size_t _saltBuffLen = 0;

    if ([_salt isKindOfClass:[NSArray class]]) {
        _saltBuff = alloca([_salt count]);
        _saltBuffLen = [_salt count];

        {
            int ii = 0;
            for (NSNumber * number in _salt) {
                _saltBuff[ii] = [number shortValue];
                ++ii;
            }
        }
    } else if ([_salt isKindOfClass:[NSString class]]) {
        _saltBuff = (uint8_t*)[_salt UTF8String];
        _saltBuffLen = [_salt length];
    } else {
        DLog(@"Scrypt salt unsupported type");
        return nil;
    }
    
    uint8_t * derivedBytes = malloc(derivedKeyLen);
    
    if (crypto_scrypt((uint8_t*)_passwordBuff, _passwordBuffLen, (uint8_t*)_saltBuff, _saltBuffLen, N, r, p, derivedBytes, derivedKeyLen) == -1) {
        return nil;
    }
    
    return [NSData dataWithBytesNoCopy:derivedBytes length:derivedKeyLen];
}

#pragma mark - JS Exception handler

- (void)jsUncaughtException:(NSString*)message url:(NSString*)url lineNumber:(NSNumber*)lineNumber
{
    
    NSString * decription = [NSString stringWithFormat:@"Javscript Exception: %@ File: %@ lineNumber: %@", message, url, lineNumber];
    
#ifndef DEBUG
    NSException * exception = [[NSException alloc] initWithName:@"Uncaught Exception" reason:decription userInfo:nil];
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0ul), ^{
        [UncaughtExceptionHandler logException:exception walletIsLoaded:[self.webView isLoaded] walletIsInitialized:[self isInitialized]];
    });
#endif
    
    [app standardNotify:decription];
}

#pragma mark - Settings Helpers

- (BOOL)hasVerifiedEmail
{
    return [[self.accountInfo objectForKey:DICTIONARY_KEY_ACCOUNT_SETTINGS_EMAIL_VERIFIED] boolValue];
}

- (BOOL)hasVerifiedMobileNumber
{
    return [self.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_SMS_VERIFIED] boolValue];
}

- (BOOL)hasStoredPasswordHint
{
    NSString *passwordHint = app.wallet.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_PASSWORD_HINT];
    return ![[passwordHint stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]] isEqualToString:@""] && passwordHint;
}

- (BOOL)hasEnabledTwoStep
{
    return [self.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_TWO_STEP_TYPE] intValue] != 0;
}

- (BOOL)hasBlockedTorRequests
{
    return [self.accountInfo[DICTIONARY_KEY_ACCOUNT_SETTINGS_TOR_BLOCKING] boolValue];
}

- (int)securityCenterScore
{
    int completedItems = 0;
    
    if ([self hasVerifiedEmail]) {
        completedItems++;
    }
    if (self.isRecoveryPhraseVerified) {
        completedItems++;
    }
    if ([self hasVerifiedMobileNumber]) {
        completedItems++;
    }
    if ([self hasStoredPasswordHint]) {
        completedItems++;
    }
    if ([self hasEnabledTwoStep]) {
        completedItems++;
    }
    if ([self hasBlockedTorRequests]) {
        completedItems++;
    }
    return completedItems;
}
    
#pragma mark - Debugging

- (void)useDebugSettingsIfSet
{
    NSString *serverURL = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL];
    if (serverURL) {
        [self updateServerURL:serverURL];
    }
    
    NSString *webSocketURL = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL];
    if (webSocketURL) {
        [self updateWebSocketURL:webSocketURL];
    }
    
    NSString *apiURL = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_API_URL];
    if (apiURL) {
        [self updateAPIURL:apiURL];
    }
}

@end

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
    
    [self.webView executeJS:@"MyWalletPhone.apiGetPINValue(\"%@\", \"%@\")", key, pin];
}

- (void)loadWalletWithGuid:(NSString*)_guid sharedKey:(NSString*)_sharedKey password:(NSString*)_password
{
    DLog(@"guid: %@, password: %@", _guid, _password);
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
    
    if ([delegate respondsToSelector:@selector(walletJSReady)])
        [delegate walletJSReady];
    
    if ([delegate respondsToSelector:@selector(walletDidLoad)])
        [delegate walletDidLoad];
    
    if (self.guid && self.password) {
        DLog(@"Fetch Wallet");
        
        if (!self.twoFactorInput) {
            [self.webView executeJS:@"MyWalletPhone.login(\"%@\", \"%@\", false, \"%@\")", [self.guid escapeStringForJS], [self.sharedKey escapeStringForJS], [self.password escapeStringForJS]];
        } else {
            [self.webView executeJS:@"MyWalletPhone.login(\"%@\", \"%@\", false, \"%@\", \"%@\")", [self.guid escapeStringForJS], [self.sharedKey escapeStringForJS], [self.password escapeStringForJS], [self.twoFactorInput escapeStringForJS]];
        }
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

- (CGFloat)getStrengthForPassword:(NSString *)passwordString
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
    // TODO disable the email warning until next start - not ideal, but there is no easy way to check if the email is set
    app.showEmailWarning = NO;
    
    if ([self isInitialized])
        [self.webView executeJS:@"MyWalletPhone.get_wallet_and_history()"];
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

- (void)verifyEmailWithCode:(NSString *)code{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.verify_email(\"%@\")", [code escapeStringForJS]];
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

- (void)cancelTxSigning
{
    if (![self.webView isLoaded]) {
        return;
    }
    
    [self.webView executeJSSynchronous:@"MyWalletPhone.cancelTxSigning();"];
}

- (void)sendPaymentWithListener:(transactionProgressListeners*)listener
{
    NSString * txProgressID = [self.webView executeJSSynchronous:@"MyWalletPhone.quickSend()"];
        
    [self.transactionProgressListeners setObject:listener forKey:txProgressID];
}

- (uint64_t)parseBitcoinValue:(NSString*)input
{
    if (![self.webView isLoaded]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.precisionToSatoshiBN(\"%@\").toString()", input] longLongValue];
}

// Make a request to blockchain.info to get the session id SID in a cookie. This cookie is around for new instances of UIWebView and will be used to let the server know the user is trying to gain access from a new device. The device is recognized based on the SID.
- (void)loadWalletLogin
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@wallet/login", WebROOT]];
    NSURLRequest *requestObj = [NSURLRequest requestWithURL:url];
    [webView loadRequest:requestObj];
}

- (void)parsePairingCode:(NSString*)code
{
    [self.webView executeJS:@"MyWalletPhone.parsePairingCode(\"%@\");", [code escapeStringForJS]];
}

// Pairing code JS callbacks
- (void)ask_for_private_key:(NSString*)address success:(void(^)(id))_success error:(void(^)(id))_error
{
    DLog(@"ask_for_private_key:");
    
    if ([delegate respondsToSelector:@selector(askForPrivateKey:success:error:)])
        [delegate askForPrivateKey:address success:_success error:_error];
}

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
#ifdef HD_ENABLED
    [self.webView executeJS:@"MyWalletPhone.newAccount(\"%@\", \"%@\", \"%@\", \"%@\")", [__password escapeStringForJS], [__email escapeStringForJS], BC_STRING_MY_BITCOIN_WALLET, nil];
#else
    // make a legacy wallet
    [self.webView executeJS:@"MyWalletPhone.newAccount(\"%@\", \"%@\", \"%@\", %i)", [__password escapeStringForJS], [__email escapeStringForJS], [@"" escapeStringForJS], 0];
#endif
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

- (Boolean)isArchived:(NSString*)address
{
    if (![self isInitialized]) {
        return FALSE;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.key(\"%@\").archived", [address escapeStringForJS]] boolValue];
}

- (BOOL)isValidAddress:(NSString*)string
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.isValidAddress(\"%@\");", [string escapeStringForJS]] boolValue];
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
    
    self.isSyncingForTrivialProcess = YES;
    
    [self.webView executeJS:@"MyWalletPhone.setLabelForAddress(\"%@\", \"%@\")", [address escapeStringForJS], [label escapeStringForJS]];
}

- (void)archiveLegacyAddress:(NSString*)address
{
    if (![self isInitialized] || ![app checkInternetConnection]) {
        return;
    }
    
    self.isSyncingForCriticalProcess = YES;
    
    [self.webView executeJS:@"MyWallet.wallet.key(\"%@\").archived = true", [address escapeStringForJS]];
    
    [self getHistory];
}

- (void)unArchiveLegacyAddress:(NSString*)address
{
    if (![self isInitialized] || ![app checkInternetConnection]) {
        return;
    }
    
    self.isSyncingForCriticalProcess = YES;
    
    [self.webView executeJS:@"MyWallet.wallet.key(\"%@\").archived = false", [address escapeStringForJS]];
    
    [self getHistory];
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
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.addPrivateKey(\"%@\")", [privateKeyString escapeStringForJS]] boolValue];
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

- (void)changePaymentFromAccount:(int)fromInt
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.changePaymentFrom(%d)", fromInt];
}

- (void)changePaymentFromAddress:(NSString *)fromString
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.changePaymentFrom(\"%@\")", [fromString escapeStringForJS]];
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

- (void)sweepPayment
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.sweepPayment()"];
}

- (void)checkIfOverspending
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.checkIfUserIsOverSpending()"];
}

- (void)getPaymentFee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJS:@"MyWalletPhone.getPaymentFee()"];
}

- (void)setTransactionFee:(uint64_t)feePerKb
{
    if (![self isInitialized]) {
        return;
    }
    
    self.isSyncingForCriticalProcess = YES;
    [self.webView executeJS:@"MyWalletPhone.setTransactionFee(%lld)", feePerKb];
}

- (uint64_t)getTransactionFee
{
    if (![self isInitialized]) {
        return 0;
    }
    
    id fee = [self.webView executeJSSynchronous:@"MyWalletPhone.getTransactionFee()"];
    if ([fee intValue] < 0) {
        DLog(@"Error retrieving fee");
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:NO] forKey:USER_DEFAULTS_KEY_LOADED_SETTINGS];
        return 0;
    } else {
        return [fee longLongValue];
    }
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
    
    self.emptyAccountIndex = 0;
    self.recoveredAccountIndex = 0;
    [self.webView executeJS:@"MyWalletPhone.recoverWithPassphrase(\"%@\",\"%@\",\"%@\")", [email escapeStringForJS], [recoveryPassword escapeStringForJS], [passphrase escapeStringForJS]];
}

- (void)resendTwoFactorSMS
{
    if ([self.webView isLoaded]) {
        [self.webView executeJS:@"MyWalletPhone.resendTwoFactorSms(\"%@\")", [self.guid escapeStringForJS]];
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

- (void)tx_on_success:(NSString*)txProgressID
{
    transactionProgressListeners *listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_success) {
            listener.on_success();
        }
    }
}

- (void)tx_on_error:(NSString*)txProgressID error:(NSString*)error
{
    transactionProgressListeners *listener = [self.transactionProgressListeners objectForKey:txProgressID];
    
    if (listener) {
        if (listener.on_error) {
            listener.on_error(error);
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
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING_ACCOUNT];
}

- (void)loading_start_new_account
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING_WALLET];
}

- (void)loading_start_import_private_key
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_IMPORT_KEY];
}

- (void)loading_start_generate_new_address
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_GENERATING_NEW_ADDRESS];
}

- (void)loading_start_generate_uuids
{
    [app updateBusyViewLoadingText:BC_STRING_LOADING_RECOVERY_CREATING_WALLET];
}

- (void)loading_start_recover_wallet
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_RECOVERING_WALLET];
}

- (void)loading_stop
{
    DLog(@"Stop loading");
    [app hideBusyView];
}

- (void)upgrade_success
{
    [app standardNotify:BC_STRING_UPGRADE_SUCCESS title:BC_STRING_UPGRADE_SUCCESS_TITLE delegate:nil];
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
    NSString *twoFactorType = [app.wallet get2FAType];
    if ([twoFactorType intValue] == TWO_STEP_AUTH_TYPE_GOOGLE) {
        [app verifyTwoFactorGoogle];
    } else if ([twoFactorType intValue] == TWO_STEP_AUTH_TYPE_SMS) {
        [app verifyTwoFactorSMS];
    } else if ([twoFactorType intValue] == TWO_STEP_AUTH_TYPE_YUBI_KEY) {
        [app verifyTwoFactorYubiKey];
    } else {
        [app standardNotifyAutoDismissingController:BC_STRING_INVALID_AUTHENTICATION_TYPE];
    }
}

- (void)on_block
{
    DLog(@"on_block");
}

- (void)did_set_latest_block
{
    DLog(@"did_set_latest_block");
    
    [self.webView executeJSWithCallback:^(NSString* latestBlockJSON) {
        
        [[NSUserDefaults standardUserDefaults] setObject:latestBlockJSON forKey:USER_DEFAULTS_KEY_TRANSACTIONS];
        
        [self parseLatestBlockJSON:latestBlockJSON];
        
    } command:@"JSON.stringify(WalletStore.getLatestBlock())"];
}

- (void)parseLatestBlockJSON:(NSString*)latestBlockJSON
{
    NSDictionary *dict = [latestBlockJSON getJSONObject];
    
    LatestBlock *latestBlock = [[LatestBlock alloc] init];
    
    latestBlock.height = [[dict objectForKey:@"height"] intValue];
    latestBlock.time = [[dict objectForKey:@"time"] longLongValue];
    latestBlock.blockIndex = [[dict objectForKey:@"block_index"] intValue];
    
    [delegate didSetLatestBlock:latestBlock];
}

- (void)did_multiaddr
{
    DLog(@"did_multiaddr");
    
    [self getFinalBalance];
    
    [self.webView executeJSWithCallback:^(NSString * multiAddrJSON) {
        MultiAddressResponse *response = [self parseMultiAddrJSON:multiAddrJSON];
        
        response.transactions = [NSMutableArray array];
        
        NSArray *transactionsArray = [self getAllTransactions];
        
        for (NSDictionary *dict in transactionsArray) {
            Transaction *tx = [Transaction fromJSONDict:dict];
            
            [response.transactions addObject:tx];
        }
        
        if (!self.isSyncingForCriticalProcess) {
            [self loading_stop];
        }
        
        [delegate didGetMultiAddressResponse:response];
    } command:@"JSON.stringify(MyWalletPhone.getMultiAddrResponse())"];
}

- (MultiAddressResponse *)parseMultiAddrJSON:(NSString*)multiAddrJSON
{
    if (multiAddrJSON == nil)
        return nil;
    
    NSDictionary *dict = [multiAddrJSON getJSONObject];
    
    MultiAddressResponse *response = [[MultiAddressResponse alloc] init];
        
    response.final_balance = [[dict objectForKey:@"final_balance"] longLongValue];
    response.total_received = [[dict objectForKey:@"total_received"] longLongValue];
    response.n_transactions = [[dict objectForKey:@"n_transactions"] unsignedIntValue];
    response.total_sent = [[dict objectForKey:@"total_sent"] longLongValue];
    response.addresses = [dict objectForKey:@"addresses"];
    
    {
        NSDictionary *symbolLocalDict = [dict objectForKey:@"symbol_local"] ;
        if (symbolLocalDict) {
            response.symbol_local = [CurrencySymbol symbolFromDict:symbolLocalDict];
        }
    }
    
    {
        NSDictionary *symbolBTCDict = [dict objectForKey:@"symbol_btc"] ;
        if (symbolBTCDict) {
            response.symbol_btc = [CurrencySymbol symbolFromDict:symbolBTCDict];
        }
    }
    
    return response;
}

- (NSArray *)getAllTransactions
{
    if (![self.webView isLoaded]) {
        return nil;
    }
    
    NSString *allTransactionsJSON = [self.webView executeJSSynchronous:@"JSON.stringify(WalletStore.getAllTransactions())"];
    
    return [allTransactionsJSON getJSONObject];
}

- (void)on_tx
{
    DLog(@"on_tx");

    [app playBeepSound];
    
    [app.transactionsViewController animateNextCellAfterReload];
    
    [self getHistory];
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
    
#ifndef HD_ENABLED
    if ([self hasAccount]) {
        // Prevent email authorization message from appearing
        return;
    }
#endif
    
    // Don't display an error message for this notice, instead show a note in the sideMenu
    if ([message isEqualToString:@"For Improved security add an email address to your account."]) {
        app.showEmailWarning = YES;
        
        return;
    }
    
    NSRange invalidEmailStringRange = [message rangeOfString:@"update-email-error" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (invalidEmailStringRange.location != NSNotFound) {
        [self performSelector:@selector(on_update_email_error) withObject:nil afterDelay:0.1f];
        return;
    }
    
    NSRange authorizationRequiredStringRange = [message rangeOfString:@"Authorization Required" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (authorizationRequiredStringRange.location != NSNotFound) {
        [app standardNotify:BC_STRING_MANUAL_PAIRING_AUTHORIZATION_REQUIRED_MESSAGE title:BC_STRING_MANUAL_PAIRING_AUTHORIZATION_REQUIRED_TITLE delegate:nil];
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
    
    NSRange updatePasswordHintErrorStringRange = [message rangeOfString:@"password-hint1" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (updatePasswordHintErrorStringRange.location != NSNotFound) {
        [self performSelector:@selector(on_update_password_hint_error) withObject:nil afterDelay:0.1f];
        return;
    }
    
    NSRange incorrectPasswordErrorStringRange = [message rangeOfString:@"Please check your password is correct" options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
    if (incorrectPasswordErrorStringRange.location != NSNotFound && ![app guid]) {
        // Error message shown in error_other_decrypting_wallet without guid
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
        NSRange range = [message rangeOfString:BC_STRING_IDENTIFIER options:NSCaseInsensitiveSearch range:NSMakeRange(0, message.length) locale:[NSLocale currentLocale]];
        if (range.location != NSNotFound) {
            [app standardNotify:message title:BC_STRING_ERROR delegate:nil];
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
    
#ifndef HD_ENABLED
    if ([self hasAccount]) {
        uint64_t walletVersion = [[self.webView executeJSSynchronous:@"APP_VERSION"] longLongValue];
        [app standardNotify:[[NSString alloc] initWithFormat:BC_STRING_WALLET_VERSION_NOT_SUPPORTED, walletVersion]];
        // prevent assignment of GUID/sharedKey
        return;
    }
#endif
    
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

#ifndef HD_ENABLED
    if ([self hasAccount]) {
        // prevent the PIN screen from loading
        return;
    }
#endif
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
    self.isSyncingForCriticalProcess = YES;

    [app showBusyViewWithLoadingText:BC_STRING_LOADING_IMPORT_KEY];
}

- (void)on_add_private_key:(NSString*)address
{
    DLog(@"on_add_private_key");
    self.isSyncingForCriticalProcess = YES;

    if ([delegate respondsToSelector:@selector(didImportPrivateKey:)]) {
        [delegate didImportPrivateKey:address];
    }
}

- (void)on_error_adding_private_key:(NSString*)error
{
    if ([delegate respondsToSelector:@selector(didFailToImportPrivateKey:)]) {
        [delegate didFailToImportPrivateKey:error];
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
    if (self.isSyncingForTrivialProcess) {
        [self loading_stop];
        self.isSyncingForTrivialProcess = NO;
    }
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
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_SCANNED_NEW_ADDRESS object:nil];
    // Hide the busy view if setting fee per kb or generating new address - the call to backup the wallet is waiting on this setter to finish
    [self loading_stop];
    self.isSyncingForCriticalProcess = NO;
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
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHANGE_LOCAL_CURRENCY_SUCCESS object:nil];
}

- (void)on_change_currency_error
{
    DLog(@"on_change_local_currency_error");
    [app standardNotify:BC_STRING_SETTINGS_ERROR_LOADING_MESSAGE title:BC_STRING_SETTINGS_ERROR_UPDATING_TITLE delegate:nil];
}

- (void)on_get_account_info_success:(NSString *)accountInfo
{
    DLog(@"on_get_account_info");
    NSDictionary *accountInfoDictionary = [accountInfo getJSONObject];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil userInfo:accountInfoDictionary];
}

- (void)on_get_all_currency_symbols_success:(NSString *)currencies
{
    DLog(@"on_get_all_currency_symbols_success");
    NSDictionary *allCurrencySymbolsDictionary = [currencies getJSONObject];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_GET_ALL_CURRENCY_SYMBOLS_SUCCESS object:nil userInfo:allCurrencySymbolsDictionary];
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

- (void)on_verify_email_success
{
    DLog(@"on_verify_email_success");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_VERIFY_EMAIL_SUCCESS object:nil];
}

- (void)on_verify_email_error
{
    DLog(@"on_verify_email_error");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_VERIFY_EMAIL_ERROR object:nil];
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
    if (self.isSyncingForCriticalProcess) {
        // Required to prevent user input while archiving/unarchiving addresses
        [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_GET_HISTORY_SUCCESS object:nil];
}

- (void)update_fee:(NSNumber *)fee
{
    DLog(@"update_fee");
    DLog(@"Wallet: fee is %@", fee);
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_UPDATE_FEE object:nil userInfo:@{DICTIONARY_KEY_FEE:fee}];
}

- (void)update_max_amount:(NSNumber *)amount fee:(NSNumber *)fee
{
    DLog(@"update_max_amount");
    DLog(@"Wallet: max amount is %@ with fee %@", amount, fee);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_UPDATE_FEE object:nil userInfo:@{DICTIONARY_KEY_AMOUNT:amount, DICTIONARY_KEY_FEE:fee}];
}

- (void)check_max_amount:(NSNumber *)amount fee:(NSNumber *)fee
{
    DLog(@"check_max_amount");
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_CHECK_MAX_AMOUNT object:nil userInfo:@{DICTIONARY_KEY_AMOUNT:amount, DICTIONARY_KEY_FEE:fee}];
}

- (void)on_error_update_fee:(NSString *)error
{
    DLog(@"on_error_update_fee");
    
    [app standardNotify:error];
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_UPDATE_FEE object:nil userInfo:@{@"error":error}];
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
        [app standardNotify:BC_STRING_INVALID_RECOVERY_PHRASE];
    } else if ([error isEqualToString:@""]) {
        [app standardNotify:BC_STRING_NO_INTERNET_CONNECTION];
    } else if ([error isEqualToString:ERROR_TIMEOUT_REQUEST]){
        [app standardNotify:BC_STRING_TIMED_OUT];
    } else {
        [app standardNotify:error];
    }
    if ([delegate respondsToSelector:@selector(didFailRecovery)])
        [delegate didFailRecovery];
}

- (void)on_progress_recover_with_passphrase:(NSString *)totalReceived finalBalance:(NSString *)finalBalance
{
    uint64_t fundsInAccount = [finalBalance longLongValue];
    
    if ([totalReceived longLongValue] == 0) {
        self.emptyAccountIndex++;
        [app updateBusyViewLoadingText:[NSString stringWithFormat:BC_STRING_LOADING_RECOVERING_WALLET_CHECKING_ARGUMENT_TEN_ACCOUNTS, self.emptyAccountIndex]];
    } else {
        self.emptyAccountIndex = 0;
        self.recoveredAccountIndex++;
        [app updateBusyViewLoadingText:[NSString stringWithFormat:BC_STRING_LOADING_RECOVERING_WALLET_ACCOUNT_ARGUMENT_FUNDS_ARGUMENT, self.recoveredAccountIndex, [app formatMoney:fundsInAccount]]];
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

# pragma mark - Calls from Obj-C to JS for HD wallet

- (void)whitelistWallet
{
    DLog(@"Whitelisting newly created wallet");
    [self.webView executeJS:@"MyWallet.wallet.whitelistWallet('HvWJeR1WdybHvq0316i', 'alpha')"];
}

- (void)upgradeToHDWallet
{
    DLog(@"Creating HD Wallet");
    [self.webView executeJS:@"MyWalletPhone.upgradeToHDWallet(\"%@\");", NSLocalizedString(@"My Bitcoin Wallet", nil)];
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
#ifdef HD_ENABLED
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.isUpgradedToHD"] boolValue];
#else
    return NO;
#endif
}

- (void)getRecoveryPhrase:(NSString *)secondPassword;
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.webView executeJSSynchronous:@"MyWalletPhone.getRecoveryPhrase(\"%@\")", secondPassword];
}

- (BOOL)isRecoveryPhraseVerified {
    if (![self isInitialized]) {
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

- (int)getAccountsCount
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.getAccountsCount()"] intValue];
}

- (int)getDefaultAccountIndex
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.webView executeJSSynchronous:@"MyWalletPhone.getDefaultAccountIndex()"] intValue];
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
    
    return [[self.webView executeJSSynchronous:@"MyWallet.wallet.balanceSpendableActive"] longLongValue];
}

- (uint64_t)getTotalBalanceForActiveLegacyAddresses
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
        self.isSyncingForTrivialProcess = YES;
        [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
        [self.webView executeJSSynchronous:@"MyWalletPhone.setLabelForAccount(%d, \"%@\")", account, label];
    }
}

- (void)createAccountWithLabel:(NSString *)label
{
    if ([self isInitialized] && [app checkInternetConnection]) {
        // Show loading text
        [self loading_start_create_account];
        
        self.isSyncingForCriticalProcess = YES;
        
        // Wait a little bit to make sure the loading text is showing - then execute the blocking and kind of long create account
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self.webView executeJSSynchronous:@"MyWalletPhone.createAccount(\"%@\")", label];
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
            [app hideBusyView];
            
            if (data) {
                _success([data hexadecimalString]);
            } else {
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

@end

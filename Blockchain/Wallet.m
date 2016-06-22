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
#import <JavaScriptCore/JavaScriptCore.h>
#import "ModuleXMLHTTPRequest.h"
#import <openssl/evp.h>

@interface Wallet ()
@property (nonatomic) JSContext *context;
@end

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
@synthesize sharedKey;
@synthesize guid;

- (id)init
{
    self = [super init];
    
    if (self) {
        _transactionProgressListeners = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)loadJS
{
    /* NOTE (not final):
     
     In My-Wallet-V3, you must add global.self = global; to whatwg-fetch/fetch.js.
     
     In my-wallet.js, delete the crypto line and add the following:
        var crypto = {}
        crypto.getRandomValues = function(discard) {}
     */
    
    NSString *walletJSPath = [[NSBundle mainBundle] pathForResource:@"my-wallet" ofType:@"js"];
    NSString *walletiOSPath = [[NSBundle mainBundle] pathForResource:@"wallet-ios" ofType:@"js"];
    NSString *walletJSSource = [NSString stringWithContentsOfFile:walletJSPath encoding:NSUTF8StringEncoding error:nil];
    NSString *walletiOSSource = [NSString stringWithContentsOfFile:walletiOSPath encoding:NSUTF8StringEncoding error:nil];
    
    NSString *jsSource = [NSString stringWithFormat:@"var window = this; var navigator = {}; navigator.userAgent = {}; navigator.userAgent.match = function(){return 0};\n%@\n%@", walletJSSource, walletiOSSource];
    self.context = [[JSContext alloc] init];
    
    self.context[@"XMLHttpRequest"] = [ModuleXMLHttpRequest class];
    
    self.context.exceptionHandler = ^(JSContext *context, JSValue *exception) {
        NSString *stacktrace = [[exception objectForKeyedSubscript:@"stack"] toString];
        // type of Number
        NSString *lineNumber = [[exception objectForKeyedSubscript:@"line"] toString];
        
        DLog(@"%@ \nstack: %@\nline number: %@", [exception toString], stacktrace, lineNumber);
    };
    
    [self.context evaluateScript:@"var console = {}"];
    self.context[@"console"][@"log"] = ^(NSString *message) {
        DLog(@"Javascript log: %@",message);
    };
    
    // Add setTimout
    self.context[@"setTimeout"] = ^(JSValue* function, JSValue* timeout) {
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([timeout toInt32] * NSEC_PER_MSEC)), dispatch_get_main_queue(), ^{
            [function callWithArguments:@[]];
        });
    };
    
    dispatch_queue_t jsQueue = dispatch_queue_create("com.some.identifier",
                                                     DISPATCH_QUEUE_SERIAL);
    
    self.context[@"setInterval"] = ^(int ms, JSValue *callback) {
        NSTimer *timer = [NSTimer scheduledTimerWithTimeInterval:ms/1000
                                                          target:[NSBlockOperation blockOperationWithBlock:^{
            dispatch_async(jsQueue, ^{
                [callback callWithArguments:nil];
            });
        }]
                                                        selector:@selector(main)
                                                        userInfo:nil
                                                         repeats:YES];
        [timer fire];
    };
    
    __weak Wallet *weakSelf = self;
    self.context[@"on_pin_code_get_response"] = ^(NSDictionary *response) {
        [weakSelf on_pin_code_get_response:response];
    };
    
    self.context[@"loading_start_download_wallet"] = ^(){
        [weakSelf loading_start_download_wallet];
    };
    
    self.context[@"loading_stop"] = ^(){
        [weakSelf loading_stop];
    };
    
    self.context[@"did_load_wallet"] = ^(){
        [weakSelf did_load_wallet];
    };
    
    self.context[@"did_decrypt"] = ^(){
        [weakSelf did_decrypt];
    };
    
    self.context[@"loading_start_decrypt_wallet"] = ^(){
        [weakSelf loading_start_decrypt_wallet];
    };
    
    self.context[@"loading_start_build_wallet"] = ^(){
        [weakSelf loading_start_build_wallet];
    };
    
    self.context[@"loading_start_multiaddr"] = ^(){
        [weakSelf loading_start_multiaddr];
    };
    
    self.context[@"did_set_latest_block"] = ^(){
        [weakSelf did_set_latest_block];
    };
    
    self.context[@"did_multiaddr"] = ^(){
        [weakSelf did_multiaddr];
    };
    
    self.context[@"loading_start_get_history"] = ^(){
        [weakSelf loading_start_get_history];
    };
    
    self.context[@"on_get_history_success"] = ^(){
        [weakSelf on_get_history_success];
    };
    
    self.context[@"update_send_balance"] = ^(NSNumber *balance) {
        [weakSelf update_send_balance:balance];
    };
    
    self.context[@"update_surge_status"] = ^(NSNumber *surgeStatus) {
        [weakSelf update_surge_status:surgeStatus];
    };
    
    self.context[@"did_change_forced_fee_dust"] = ^(NSNumber *fee, NSNumber *dust) {
        [weakSelf did_change_forced_fee:fee dust:dust];
    };
    
    self.context[@"update_fee_bounds_confirmationEstimation_maxAmounts_maxFees"] = ^(NSArray *absoluteFeeBounds, NSNumber *expectedBlock, NSArray *maxSpendableAmounts, NSArray *sweepFees) {
        [weakSelf update_fee_bounds:absoluteFeeBounds confirmationEstimation:expectedBlock maxAmounts:maxSpendableAmounts maxFees:sweepFees];
    };
    
    self.context[@"update_max_amount_fee_dust_willConfirm"] = ^(NSNumber *maxAmount, NSNumber *fee, NSNumber *dust, NSNumber *willConfirm) {
        [weakSelf update_max_amount:maxAmount fee:fee dust:dust willConfirm:willConfirm];
    };
    
    self.context[@"check_max_amount_fee"] = ^(NSNumber *amount, NSNumber *fee) {
        [weakSelf check_max_amount:amount fee:fee];
    };
    
    self.context[@"did_get_fee_dust"] = ^(NSNumber *fee, NSNumber *dust) {
        [weakSelf did_get_fee:fee dust:dust];
    };
    
    self.context[@"tx_on_success_secondPassword"] = ^(NSString *success, NSString *secondPassword) {
        [weakSelf tx_on_success:success secondPassword:secondPassword];
    };
    
    self.context[@"tx_on_start"] = ^(NSString *transactionId) {
        [weakSelf tx_on_start:transactionId];
    };
    
    self.context[@"tx_on_begin_signing"] = ^(NSString *transactionId) {
        [weakSelf tx_on_begin_signing:transactionId];
    };
    
    self.context[@"tx_on_sign_progress_input"] = ^(NSString *transactionId, NSString *input) {
        [weakSelf tx_on_sign_progress:transactionId input:input];
    };
    
    self.context[@"tx_on_finish_signing"] = ^(NSString *transactionId) {
        [weakSelf tx_on_finish_signing:transactionId];
    };
    
    self.context[@"didParsePairingCode"] = ^(NSDictionary *pairingCode) {
        [weakSelf didParsePairingCode:pairingCode];
    };
    
    self.context[@"errorParsingPairingCode"] = ^(NSString *error) {
        [weakSelf errorParsingPairingCode:error];
    };
    
    self.context[@"error_restoring_wallet"] = ^(){
        [weakSelf error_restoring_wallet];
    };
    
    self.context[@"on_pin_code_put_response"] = ^(NSDictionary *response) {
        [weakSelf on_pin_code_put_response:response];
    };
    
    self.context[@"getSecondPassword"] = ^(JSValue *secondPassword) {
        [weakSelf getSecondPassword:nil success:secondPassword error:nil];
    };
    
    self.context[@"getPrivateKeyPassword"] = ^(JSValue *privateKeyPassword) {
        [weakSelf getPrivateKeyPassword:nil success:privateKeyPassword error:nil];
    };
    
    self.context[@"crypto_scrypt_salt_n_r_p_dkLen"] = ^(id _password, id salt, NSNumber *N, NSNumber *r, NSNumber *p, NSNumber *derivedKeyLen, JSValue *success, JSValue *error) {
        [weakSelf crypto_scrypt:_password salt:salt n:N r:r p:p dkLen:derivedKeyLen success:success error:error];
    };
    
    self.context[@"on_add_new_account"] = ^() {
        [weakSelf on_add_new_account];
    };
    
    self.context[@"loading_start_new_account"] = ^() {
        [weakSelf loading_start_new_account];
    };
    
    self.context[@"reload"] = ^() {
        [weakSelf reload];
    };
    
    self.context[@"on_backup_wallet_start"] = ^() {
        [weakSelf on_backup_wallet_start];
    };
    
    self.context[@"on_backup_wallet_success"] = ^() {
        [weakSelf on_backup_wallet_success];
    };
    
    self.context[@"on_get_session_token"] = ^(NSString *token) {
        [weakSelf on_get_session_token:token];
    };
    
    self.context[@"ws_on_open"] = ^() {
        [weakSelf ws_on_open];
    };
    
    self.context[@"on_tx_received"] = ^() {
        [weakSelf on_tx_received];
    };
    
    self.context[@"on_add_private_key_start"] = ^() {
        [weakSelf on_add_private_key_start];
    };
    
    self.context[@"on_add_incorrect_private_key"] = ^(NSString *address) {
        [weakSelf on_add_incorrect_private_key:address];
    };
    
    self.context[@"on_add_private_key_to_legacy_address"] = ^() {
        [weakSelf on_add_private_key_to_legacy_address];
    };
    
    self.context[@"on_success_import_key_for_sending_from_watch_only"] = ^() {
        [weakSelf on_success_import_key_for_sending_from_watch_only];
    };
    
    self.context[@"on_error_import_key_for_sending_from_watch_only"] = ^(NSString *error) {
        [weakSelf on_error_import_key_for_sending_from_watch_only:error];
    };
    
    self.context[@"on_get_account_info_success"] = ^(NSString *accountInfo) {
        [weakSelf on_get_account_info_success:accountInfo];
    };
    
    self.context[@"on_get_all_currency_symbols_success"] = ^(NSString *currencies) {
        [weakSelf on_get_all_currency_symbols_success:currencies];
    };
    
    self.context[@"on_error_creating_new_address"] = ^(NSString *error) {
        [weakSelf on_error_creating_new_address:error];
    };
    
    self.context[@"on_progress_recover_with_passphrase_finalBalance"] = ^(NSString *totalReceived, NSString *finalBalance) {
        [weakSelf on_progress_recover_with_passphrase:totalReceived finalBalance:finalBalance];
    };
    
    self.context[@"on_success_get_recovery_phrase"] = ^(NSString *recoveryPhrase) {
        [weakSelf on_success_get_recovery_phrase:recoveryPhrase];
    };
    
    self.context[@"on_success_recover_with_passphrase"] = ^(NSDictionary *totalReceived, NSString *finalBalance) {
        [weakSelf on_success_recover_with_passphrase:totalReceived];
    };
    
    self.context[@"on_error_recover_with_passphrase"] = ^(NSString *error) {
        [weakSelf on_error_recover_with_passphrase:error];
    };
    
    self.context[@"on_error_add_new_account"] = ^(NSString *error) {
        [weakSelf on_error_add_new_account:error];
    };
    
    self.context[@"on_error_update_fee"] = ^(NSDictionary *error) {
        [weakSelf on_error_update_fee:error];
    };
    
    self.context[@"on_error_get_history"] = ^(NSString *error) {
        [weakSelf on_error_get_history:error];
    };
    
    self.context[@"on_error_creating_new_account"] = ^(NSString *error) {
        [weakSelf on_error_creating_new_account:error];
    };
    
    self.context[@"error_other_decrypting_wallet"] = ^(NSString *error) {
        [weakSelf error_other_decrypting_wallet:error];
    };
    
    self.context[@"on_add_key"] = ^(NSString *key) {
        [weakSelf on_add_key:key];
    };
    
    self.context[@"on_error_adding_private_key"] = ^(NSString *key) {
        [weakSelf on_error_adding_private_key:key];
    };
    
    self.context[@"on_error_import_key_for_sending_from_watch_only"] = ^(NSString *key) {
        [weakSelf on_error_import_key_for_sending_from_watch_only:key];
    };
    
    self.context[@"on_add_incorrect_private_key"] = ^(NSString *key) {
        [weakSelf on_add_incorrect_private_key:key];
    };
    
    self.context[@"on_error_adding_private_key_watch_only"] = ^(NSString *key) {
        [weakSelf on_error_adding_private_key_watch_only:key];
    };
    
    self.context[@"update_transfer_all_amount_fee_addressesUsed"] = ^(NSNumber *amount, NSNumber *fee, NSArray *addressesUsed) {
        [weakSelf update_transfer_all_amount:amount fee:fee addressesUsed:addressesUsed];
    };
    
    self.context[@"loading_start_transfer_all"] = ^(NSNumber *index) {
        [weakSelf loading_start_transfer_all:index];
    };
    
    self.context[@"loading_start_generate_uuids"] = ^() {
        [weakSelf loading_start_generate_uuids];
    };
    
    self.context[@"loading_start_recover_wallet"] = ^() {
        [weakSelf loading_start_recover_wallet];
    };
    
    self.context[@"update_loaded_all_transactions"] = ^(NSNumber *index) {
        [weakSelf update_loaded_all_transactions:index];
    };
    
    self.context[@"tx_on_error_error_secondPassword"] = ^(NSString *txId, NSString *error, NSString *secondPassword) {
        [weakSelf tx_on_error:txId error:error secondPassword:secondPassword];
    };
    
    self.context[@"on_error_transfer_all_secondPassword"] = ^(NSString *error, NSString *secondPassword) {
        [weakSelf on_error_transfer_all:error secondPassword:secondPassword];
    };
    
    self.context[@"send_transfer_all"] = ^(NSString *secondPassword) {
        [weakSelf send_transfer_all:secondPassword];
    };
    
    self.context[@"on_payment_notice"] = ^(NSString *notice) {
        [weakSelf on_payment_notice:notice];
    };
    
    self.context[@"on_resend_two_factor_sms_success"] = ^() {
        [weakSelf on_resend_two_factor_sms_success];
    };
    
    self.context[@"on_change_local_currency_success"] = ^() {
        [weakSelf on_change_local_currency_success];
    };
    
    self.context[@"on_change_currency_error"] = ^() {
        [weakSelf on_change_currency_error];
    };
    
    self.context[@"on_change_email_success"] = ^() {
        [weakSelf on_change_email_success];
    };
    
    self.context[@"on_change_email_notifications_success"] = ^() {
        [weakSelf on_change_email_notifications_success];
    };
    
    self.context[@"on_change_email_notifications_error"] = ^() {
        [weakSelf on_change_email_notifications_error];
    };
    
    self.context[@"on_resend_two_factor_sms_error"] = ^(NSString *error) {
        [weakSelf on_resend_two_factor_sms_error:error];
    };
    
    self.context[@"on_update_tor_success"] = ^() {
        [weakSelf on_update_tor_success];
    };
    
    self.context[@"on_update_tor_error"] = ^() {
        [weakSelf on_update_tor_error];
    };
    
    self.context[@"on_change_two_step_success"] = ^() {
        [weakSelf on_change_two_step_success];
    };
    
    self.context[@"on_change_two_step_error"] = ^() {
        [weakSelf on_change_two_step_error];
    };
    
    self.context[@"on_update_password_hint_success"] = ^() {
        [weakSelf on_update_password_hint_success];
    };
    
    self.context[@"on_update_password_hint_error"] = ^() {
        [weakSelf on_update_password_hint_error];
    };
    
    self.context[@"on_change_password_success"] = ^() {
        [weakSelf on_change_password_success];
    };
    
    self.context[@"on_change_password_error"] = ^() {
        [weakSelf on_change_password_error];
    };
    
    self.context[@"on_verify_mobile_number_success"] = ^() {
        [weakSelf on_verify_mobile_number_success];
    };
    
    self.context[@"on_verify_mobile_number_error"] = ^() {
        [weakSelf on_verify_mobile_number_error];
    };
    
    self.context[@"on_change_mobile_number_success"] = ^() {
        [weakSelf on_change_mobile_number_success];
    };
    
    self.context[@"on_resend_verification_email_success"] = ^() {
        [weakSelf on_resend_verification_email_success];
    };

    self.context[@"getRandomBytes"] = ^(NSNumber *count) {
        DLog(@"getObjCRandomValues");
        NSFileHandle *fileHandle = [NSFileHandle fileHandleForReadingAtPath:@"/dev/random"];
        if (!fileHandle) {
            return @"";
        }
        NSData *data = [fileHandle readDataOfLength:[count intValue]];
        return [data hexadecimalString];
    };
    
    self.context[@"on_create_new_account_sharedKey_password"] = ^(NSString *_guid, NSString *_sharedKey, NSString *_password) {
        [weakSelf on_create_new_account:_guid sharedKey:_sharedKey password:_password];
    };
    
    self.context[@"objc_sjcl_misc_pbkdf2"] = ^(NSString *_password, id _salt, int iterations, int keylength, NSString *hmacSHA1) {
        
        uint8_t * finalOut = malloc(keylength);
        
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
            return [[NSData new] hexadecimalString];
        }
        
        if (PKCS5_PBKDF2_HMAC_SHA1([_password UTF8String], (int)_password.length, _saltBuff, (int)_saltBuffLen, iterations, keylength, finalOut) == 0) {
            return [[NSData new] hexadecimalString];
        };
        
        return [[NSData dataWithBytesNoCopy:finalOut length:keylength] hexadecimalString];
    };
    
    [self.context evaluateScript:jsSource];
    
    [self login];
}

- (void)setupWebSocket
{
    NSMutableURLRequest *webSocketRequest = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:DEFAULT_WEBSOCKET_SERVER]];
    [webSocketRequest addValue:DEFAULT_WALLET_SERVER forHTTPHeaderField:@"Origin"];
    self.webSocket = [[SRWebSocket alloc] initWithURLRequest:webSocketRequest];
    self.webSocket.delegate = self;
    
    [self.webSocketTimer invalidate];
    self.webSocketTimer = nil;
    self.webSocketTimer = [NSTimer scheduledTimerWithTimeInterval:15.0
                                     target:self
                                   selector:@selector(pingWebSocket)
                                   userInfo:nil
                                    repeats:YES];
    
    [self.webSocket open];
}

- (void)pingWebSocket
{
    if (self.webSocket.readyState == 1) {
        [self.webSocket sendPing:[@"{ op: 'ping' }" dataUsingEncoding:NSUTF8StringEncoding]];
    } else {
        DLog(@"reconnecting websocket");
        [self setupWebSocket];
    }
}

- (void)apiGetPINValue:(NSString*)key pin:(NSString*)pin
{
    [self loadJS];
    
    [self useDebugSettingsIfSet];
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.apiGetPINValue(\"%@\", \"%@\")", key, pin]];
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

- (void)login
{
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
        
        [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.login(\"%@\", \"%@\", false, \"%@\", \"%@\", \"%@\")", [self.guid escapeStringForJS], escapedSharedKey, [self.password escapeStringForJS], escapedSessionToken, escapedTwoFactorInput]];
    }
}

# pragma mark - Socket Delegate

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    DLog(@"websocket opened");
    NSString *message = [[self.context evaluateScript:@"MyWallet.getSocketOnOpenMessage()"] toString];
    [webSocket sendString:message];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    DLog(@"websocket closed: code %li, reason: %@", code, reason);
    if (self.webSocket.readyState != 1) {
        DLog(@"reconnecting websocket");
        [self setupWebSocket];
    }
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceivePong:(NSData *)pongData
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithData:(NSData *)data
{
    
}

- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessageWithString:(NSString *)string
{
    DLog(@"received websocket message string");
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWallet.getSocketOnMessage(\"%@\")", [string escapeStringForJS]]];
}

# pragma mark - Calls from Obj-C to JS

- (BOOL)isInitialized
{
    // Initialized when the webView is loaded and the wallet is initialized (decrypted and in-memory wallet built)
    BOOL isInitialized = [[self.context evaluateScript:@"MyWallet.getIsInitialized()"] toBool];
    if (!isInitialized) {
        DLog(@"Warning: Wallet not initialized!");
    }
    
    return isInitialized;
}

- (BOOL)hasEncryptedWalletData
{
    if ([self isInitialized])
    return [[self.context evaluateScript:@"MyWalletPhone.hasEncryptedWalletData()"] toBool];
    else
    return NO;
}

- (void)pinServerPutKeyOnPinServerServer:(NSString*)key value:(NSString*)value pin:(NSString*)pin
{
    if (![self isInitialized]) {
        return;
    }
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.pinServerPutKeyOnPinServerServer(\"%@\", \"%@\", \"%@\")", key, value, pin]];
}

- (NSString*)encrypt:(NSString*)data password:(NSString*)_password pbkdf2_iterations:(int)pbkdf2_iterations
{
    return [[self.context evaluateScript:[NSString stringWithFormat:@"WalletCrypto.encrypt(\"%@\", \"%@\", %d)", [data escapeStringForJS], [_password escapeStringForJS], pbkdf2_iterations]] toString];
}

- (NSString*)decrypt:(NSString*)data password:(NSString*)_password pbkdf2_iterations:(int)pbkdf2_iterations
{
    return [[self.context evaluateScript:[NSString stringWithFormat:@"WalletCrypto.decryptPasswordWithProcessedPin(\"%@\", \"%@\", %d)", [data escapeStringForJS], [_password escapeStringForJS], pbkdf2_iterations]] toString];
}

- (float)getStrengthForPassword:(NSString *)passwordString
{
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.getPasswordStrength(\"%@\")", [passwordString escapeStringForJS]]] toDouble];
}

- (void)getHistory
{
    if ([self isInitialized])
    [self.context evaluateScript:@"MyWalletPhone.get_history()"];
}

- (void)getWalletAndHistory
{
    if ([self isInitialized])
    [self.context evaluateScript:@"MyWalletPhone.get_wallet_and_history()"];
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
        [self.context evaluateScript:@"MyWalletPhone.fetchMoreTransactions()"];
    }
}

- (int)getAllTransactionsCount
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:@"MyWalletPhone.getAllTransactionsCount()"] toInt32];
}

- (void)getAllCurrencySymbols
{
    [self.context evaluateScript:@"JSON.stringify(MyWalletPhone.getAllCurrencySymbols())"];
}

- (void)changeLocalCurrency:(NSString *)currencyCode
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changeLocalCurrency(\"%@\")", [currencyCode escapeStringForJS]]];
}

- (void)changeBtcCurrency:(NSString *)btcCode
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changeBtcCurrency(\"%@\")", [btcCode escapeStringForJS]]];
}

- (void)getAccountInfo
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"JSON.stringify(MyWalletPhone.getAccountInfo())"];
}

- (void)changeEmail:(NSString *)newEmail
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changeEmail(\"%@\")", [newEmail escapeStringForJS]]];
}

- (void)resendVerificationEmail:(NSString *)email
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.resendEmailConfirmation(\"%@\")", [email escapeStringForJS]]];
}

- (void)changeMobileNumber:(NSString *)newMobileNumber
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changeMobileNumber(\"%@\")", [newMobileNumber escapeStringForJS]]];
}

- (void)verifyMobileNumber:(NSString *)code
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.verifyMobile(\"%@\")", [code escapeStringForJS]]];
}

- (void)enableTwoStepVerificationForSMS
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.setTwoFactorSMS()"];
}

- (void)disableTwoStepVerification
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.unsetTwoFactor()"];
}

- (void)updatePasswordHint:(NSString *)hint
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.updatePasswordHint(\"%@\")", [hint escapeStringForJS]]];
}

- (void)changePassword:(NSString *)changedPassword
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changePassword(\"%@\")", [changedPassword escapeStringForJS]]];
}

- (BOOL)isCorrectPassword:(NSString *)inputedPassword
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.isCorrectMainPassword(\"%@\")", [inputedPassword escapeStringForJS]]] toBool];
}

- (void)sendPaymentWithListener:(transactionProgressListeners*)listener secondPassword:(NSString *)secondPassword
{
    NSString * txProgressID;
    
    if (secondPassword) {
        txProgressID = [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.quickSend(\"%@\")", [secondPassword escapeStringForJS]]] toString];
    } else {
        txProgressID = [[self.context evaluateScript:@"MyWalletPhone.quickSend()"] toString];
    }
    
    if (listener) {
        [self.transactionProgressListeners setObject:listener forKey:txProgressID];
    }
}

- (uint64_t)parseBitcoinValue:(NSString*)input
{
    return [[self.context evaluateScript:[NSString stringWithFormat:@"Helpers.precisionToSatoshiBN(\"%@\").toString()", [input escapeStringForJS]]] toInt32];
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
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.parsePairingCode(\"%@\");", [code escapeStringForJS]]];
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
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.newAccount(\"%@\", \"%@\", \"%@\")", [__password escapeStringForJS], [__email escapeStringForJS], BC_STRING_MY_BITCOIN_WALLET]];
}

- (BOOL)needsSecondPassword
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWallet.wallet.isDoubleEncrypted"]] toBool];
}

- (BOOL)validateSecondPassword:(NSString*)secondPassword
{
    if (![self isInitialized]) {
        return FALSE;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWallet.wallet.validateSecondPassword(\"%@\")", [secondPassword escapeStringForJS]]] toBool];
}

- (void)getFinalBalance
{
    if (![self isInitialized]) {
        return;
    }
    
    self.final_balance = [[self.context evaluateScript:@"MyWallet.wallet.finalBalance"] toUInt32];
}

- (void)getTotalSent
{
    if (![self isInitialized]) {
        return;
    }
    
    self.total_sent = [[self.context evaluateScript:@"MyWallet.wallet.totalSent"] toUInt32];
}

- (BOOL)isWatchOnlyLegacyAddress:(NSString*)address
{
    if (![self isInitialized]) {
        return false;
    }
    
    if ([self checkIfWalletHasAddress:address]) {
        return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWallet.wallet.key(\"%@\").isWatchOnly", [address escapeStringForJS]]] toBool];
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
        return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.labelForLegacyAddress(\"%@\")", [address escapeStringForJS]]] toString];
    } else {
        return nil;
    }
}

- (Boolean)isAddressArchived:(NSString *)address
{
    if (![self isInitialized] || !address) {
        return FALSE;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.isArchived(\"%@\")", [address escapeStringForJS]]] toBool];
}

- (Boolean)isActiveAccountArchived:(int)account
{
    if (![self isInitialized]) {
        return FALSE;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.isArchived(MyWalletPhone.getIndexOfActiveAccount(%d))", account]] toBool];
}

- (Boolean)isAccountArchived:(int)account
{
    if (![self isInitialized]) {
        return FALSE;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.isArchived(%d)", account]] toBool];
}

- (BOOL)isBitcoinAddress:(NSString*)string
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"Helpers.isBitcoinAddress(\"%@\");", [string escapeStringForJS]]] toBool];
}

- (NSArray*)allLegacyAddresses
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString * allAddressesJSON = [[self.context evaluateScript:@"JSON.stringify(MyWallet.wallet.addresses)"] toString];
    
    return [allAddressesJSON getJSONObject];
}

- (NSArray*)activeLegacyAddresses
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString *activeAddressesJSON = [[self.context evaluateScript:@"JSON.stringify(MyWallet.wallet.activeAddresses)"] toString];
    
    return [activeAddressesJSON getJSONObject];
}

- (NSArray*)spendableActiveLegacyAddresses
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString *spendableActiveAddressesJSON = [[self.context evaluateScript:@"JSON.stringify(MyWallet.wallet.spendableActiveAddresses)"] toString];
    
    return [spendableActiveAddressesJSON getJSONObject];
}

- (NSArray*)archivedLegacyAddresses
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString *activeAddressesJSON = [[self.context evaluateScript:@"JSON.stringify(MyWalletPhone.getLegacyArchivedAddresses())"] toString];
    
    return [activeAddressesJSON getJSONObject];
}

- (void)setLabel:(NSString*)label forLegacyAddress:(NSString*)address
{
    if (![self isInitialized] || ![app checkInternetConnection]) {
        return;
    }
    
    self.isSyncing = YES;
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.setLabelForAddress(\"%@\", \"%@\")", [address escapeStringForJS], [label escapeStringForJS]]];
}

- (void)toggleArchiveLegacyAddress:(NSString*)address
{
    if (![self isInitialized] || ![app checkInternetConnection]) {
        return;
    }
    
    self.isSyncing = YES;
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.toggleArchived(\"%@\")", [address escapeStringForJS]]];
}

- (void)toggleArchiveAccount:(int)account
{
    if (![self isInitialized] || ![app checkInternetConnection]) {
        return;
    }
    
    self.isSyncing = YES;
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.toggleArchived(%d)", account]];
}

- (void)archiveTransferredAddresses:(NSArray *)transferredAddresses
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.archiveTransferredAddresses(\"%@\")", [[transferredAddresses jsonString] escapeStringForJS]]];
}

- (uint64_t)getLegacyAddressBalance:(NSString*)address
{
    uint64_t errorBalance = 0;
    if (![self isInitialized]) {
        return errorBalance;
    }
    
    if ([self checkIfWalletHasAddress:address]) {
        return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWallet.wallet.key(\"%@\").balance", [address escapeStringForJS]]] toInt32];
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
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.addKey(\"%@\")", [privateKeyString escapeStringForJS]]] toBool];
}

- (BOOL)addKey:(NSString*)privateKeyString toWatchOnlyAddress:(NSString *)watchOnlyAddress
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.addKeyToLegacyAddress(\"%@\", \"%@\")", [privateKeyString escapeStringForJS], [watchOnlyAddress escapeStringForJS]]] toBool];
}

- (void)sendFromWatchOnlyAddress:(NSString *)watchOnlyAddress privateKey:(NSString *)privateKeyString
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.sendFromWatchOnlyAddressWithPrivateKey(\"%@\", \"%@\")", [privateKeyString escapeStringForJS], [watchOnlyAddress escapeStringForJS]]];
}

- (NSDictionary*)addressBook
{
    if (![self isInitialized]) {
        return [[NSDictionary alloc] init];
    }
    
    NSString * addressBookJSON = [[self.context evaluateScript:@"JSON.stringify(MyWallet.wallet.addressBook)"] toString];
    
    return [addressBookJSON getJSONObject];
}

- (void)addToAddressBook:(NSString*)address label:(NSString*)label
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.addAddressBookEntry(\"%@\", \"%@\")", [address escapeStringForJS], [label escapeStringForJS]]];
}

- (void)clearLocalStorage
{
    [self.context evaluateScript:@"localStorage.clear();"];
}

- (NSString*)detectPrivateKeyFormat:(NSString*)privateKeyString
{
    if (![self isInitialized]) {
        return nil;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.detectPrivateKeyFormat(\"%@\")", [privateKeyString escapeStringForJS]]] toString];
}

- (void)createNewPayment
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.createNewPayment()"];
}

- (void)changePaymentFromAccount:(int)fromInt isAdvanced:(BOOL)isAdvanced
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changePaymentFrom(%d, %d)", fromInt, isAdvanced]];
}

- (void)changePaymentFromAddress:(NSString *)fromString isAdvanced:(BOOL)isAdvanced
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changePaymentFrom(\"%@\", %d)", [fromString escapeStringForJS], isAdvanced]];
}

- (void)changePaymentToAccount:(int)toInt
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changePaymentTo(%d)", toInt]];
}

- (void)changePaymentToAddress:(NSString *)toString
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changePaymentTo(\"%@\")", [toString escapeStringForJS]]];
}

- (void)changePaymentAmount:(uint64_t)amount
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changePaymentAmount(%lld)", amount]];
}

- (void)getInfoForTransferAllFundsToDefaultAccount
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.getInfoForTransferAllFundsToDefaultAccount()"];
}

- (void)setupFirstTransferForAllFundsToDefaultAccount:(NSString *)address secondPassword:(NSString *)secondPassword
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.transferAllFundsToDefaultAccount(true, \"%@\", \"%@\")", [address escapeStringForJS], [secondPassword escapeStringForJS]]];
}

- (void)setupFollowingTransferForAllFundsToDefaultAccount:(NSString *)address secondPassword:(NSString *)secondPassword
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.transferAllFundsToDefaultAccount(false, \"%@\", \"%@\")", [address escapeStringForJS], [secondPassword escapeStringForJS]]];
}

- (void)transferFundsToDefaultAccountFromAddress:(NSString *)address
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.transferFundsToDefaultAccountFromAddress(\"%@\")", [address escapeStringForJS]]];
}

- (void)sweepPaymentRegular
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.sweepPaymentRegular()"];
}

- (void)sweepPaymentRegularThenConfirm
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.sweepPaymentRegularThenConfirm()"];
}

- (void)sweepPaymentAdvanced:(uint64_t)fee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.sweepPaymentAdvanced(%lld)", fee]];
}

- (void)sweepPaymentAdvancedThenConfirm:(uint64_t)fee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.sweepPaymentAdvancedThenConfirm(%lld)", fee]];
}

- (void)sweepPaymentThenConfirm:(BOOL)willConfirm isAdvanced:(BOOL)isAdvanced
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.sweepPaymentThenConfirm(%d, %d)", willConfirm, isAdvanced]];
}

- (void)checkIfOverspending
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.checkIfUserIsOverSpending()"];
}

- (void)changeForcedFee:(uint64_t)fee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.changeForcedFee(%lld)", fee]];
}

- (void)getFeeBounds:(uint64_t)fee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.getFeeBounds(%lld)", fee]];
}

- (void)getTransactionFee
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.getTransactionFee()"];
}

- (void)getSurgeStatus
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.getSurgeStatus()"];
}

- (uint64_t)dust
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:@"MyWalletPhone.dust()"] toInt32];
}

- (void)generateNewKey
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.generateNewAddress()"];
}

- (BOOL)checkIfWalletHasAddress:(NSString *)address
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.checkIfWalletHasAddress(\"%@\")", [address escapeStringForJS]] ] toBool];
}

- (void)recoverWithEmail:(NSString *)email password:(NSString *)recoveryPassword passphrase:(NSString *)passphrase
{
    [self useDebugSettingsIfSet];
    
    self.emptyAccountIndex = 0;
    self.recoveredAccountIndex = 0;
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.recoverWithPassphrase(\"%@\",\"%@\",\"%@\")", [email escapeStringForJS], [recoveryPassword escapeStringForJS], [passphrase escapeStringForJS]]];
}

- (void)resendTwoFactorSMS
{
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.resendTwoFactorSms(\"%@\", \"%@\")", [self.guid escapeStringForJS], [self.sessionToken escapeStringForJS]]];
}

- (NSString *)get2FAType
{
    return [[self.context evaluateScript:@"MyWalletPhone.get2FAType()"] toString];
}

- (void)enableEmailNotifications
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.enableNotifications()"];
}

- (void)disableEmailNotifications
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWalletPhone.disableNotifications()"];
}

- (void)changeTorBlocking:(BOOL)willEnable
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.updateTorIpBlock(%d)", willEnable]];
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
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.updateServerURL(\"%@\")", [newURL escapeStringForJS]]];
}

- (void)updateWebSocketURL:(NSString *)newURL
{
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.updateWebsocketURL(\"%@\")", [newURL escapeStringForJS]]];
}

- (void)updateAPIURL:(NSString *)newURL
{
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.updateAPIURL(\"%@\")", [newURL escapeStringForJS]]];
}

- (NSDictionary *)filteredWalletJSON
{
    if (![self isInitialized]) {
        return nil;
    }
    
    NSString * filteredWalletJSON = [[self.context evaluateScript:@"JSON.stringify(MyWalletPhone.filteredWalletJSON())"] toString];
    
    return [filteredWalletJSON getJSONObject];
}

- (NSString *)getXpubForAccount:(int)accountIndex
{
    if (![self isInitialized]) {
        return nil;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.getXpubForAccount(%d)", accountIndex]] toString];
}

- (BOOL)isAccountNameValid:(NSString *)name
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.isAccountNameValid(\"%@\")", [name escapeStringForJS]]] toBool];
}

- (BOOL)isAddressAvailable:(NSString *)address
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.isAddressAvailable(\"%@\")", [address escapeStringForJS]]] toBool];
}

- (BOOL)isAccountAvailable:(int)account
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.isAccountAvailable(%d)", account]] toBool];
}

- (int)getIndexOfActiveAccount:(int)account
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.getIndexOfActiveAccount(%d)", account]] toInt32];
}

- (void)getSessionToken
{
    [self.context evaluateScript:@"MyWalletPhone.getSessionToken()"];
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
    
    [self parseLatestBlockJSON:[[self.context evaluateScript:@"MyWalletPhone.didSetLatestBlock()"] toString]];
}

- (void)parseLatestBlockJSON:(NSString*)latestBlockJSON
{
    if ([latestBlockJSON isEqualToString:@""]) {
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
    
    NSString *multiAddrJSON = [[self.context evaluateScript:[NSString stringWithFormat:@"JSON.stringify(MyWalletPhone.getMultiAddrResponse(\"%@\"))", filter]] toString];
    
    MultiAddressResponse *response = [self parseMultiAddrJSON:multiAddrJSON];
    
    if (!self.isSyncing) {
        [self loading_stop];
    }
    
    [delegate didGetMultiAddressResponse:response];
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
    
    if ([delegate respondsToSelector:@selector(receivedTransactionMessage)])
        [delegate receivedTransactionMessage];
}

- (void)getPrivateKeyPassword:(NSString *)canDiscard success:(JSValue *)success error:(void(^)(id))_error
{
    [app getPrivateKeyPassword:^(NSString *privateKeyPassword) {
        [success callWithArguments:@[privateKeyPassword]];
    } error:_error];
}

- (void)getSecondPassword:(NSString *)canDiscard success:(JSValue *)success error:(void(^)(id))_error
{
    [app getSecondPassword:^(NSString *secondPassword) {
        [success callWithArguments:@[secondPassword]];
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
    
    [self setupWebSocket];
    
    if (self.didPairAutomatically) {
        self.didPairAutomatically = NO;
        [app standardNotify:[NSString stringWithFormat:BC_STRING_WALLET_PAIRED_SUCCESSFULLY_DETAIL] title:BC_STRING_WALLET_PAIRED_SUCCESSFULLY_TITLE delegate:nil];
    }
    self.sharedKey = [[self.context evaluateScript:@"MyWallet.wallet.sharedKey"] toString];
    self.guid = [[self.context evaluateScript:@"MyWallet.wallet.guid"] toString];
    
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

- (void)on_error_creating_new_address:(NSString*)error
{
    DLog(@"on_error_creating_new_address");
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
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.upgradeToV3(\"%@\");", NSLocalizedString(@"My Bitcoin Wallet", nil)]];
}

- (Boolean)hasAccount
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.context evaluateScript:@"MyWallet.wallet.isUpgradedToHD"] toBool];
}

- (Boolean)didUpgradeToHd
{
    if (![self isInitialized]) {
        return NO;
    }
    
    return [[self.context evaluateScript:@"MyWallet.wallet.isUpgradedToHD"] toBool];
}

- (void)getRecoveryPhrase:(NSString *)secondPassword;
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.getRecoveryPhrase(\"%@\")", [secondPassword escapeStringForJS]]];
}

- (BOOL)isRecoveryPhraseVerified {
    if (![self isInitialized]) {
        return NO;
    }
    
    if (![self didUpgradeToHd]) {
        return NO;
    }
    
    return [[self.context evaluateScript:@"MyWallet.wallet.hdwallet.isMnemonicVerified"] toBool];
}

- (void)markRecoveryPhraseVerified
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:@"MyWallet.wallet.hdwallet.verifyMnemonic()"];
}

- (int)getActiveAccountsCount
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:@"MyWalletPhone.getActiveAccountsCount()"] toInt32];
}

- (int)getAllAccountsCount
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:@"MyWalletPhone.getAllAccountsCount()"] toInt32];
}

- (int)getDefaultAccountIndex
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:@"MyWalletPhone.getDefaultAccountIndex()"] toInt32];
}

- (void)setDefaultAccount:(int)index
{
    if (![self isInitialized]) {
        return;
    }
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.setDefaultAccount(%d)", index]];
}

- (BOOL)hasLegacyAddresses
{
    if (![self isInitialized]) {
        return false;
    }
    
    return [[self.context evaluateScript:@"MyWallet.wallet.addresses.length > 0"] toBool];
}

- (uint64_t)getTotalActiveBalance
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:@"MyWallet.wallet.balanceActive"] toUInt32];
}

- (uint64_t)getTotalBalanceForActiveLegacyAddresses
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:@"MyWallet.wallet.balanceActiveLegacy"] toUInt32];
}

- (uint64_t)getTotalBalanceForSpendableActiveLegacyAddresses
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:@"MyWallet.wallet.balanceSpendableActiveLegacy"] toUInt32];
}

- (uint64_t)getBalanceForAccount:(int)account
{
    if (![self isInitialized]) {
        return 0;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.getBalanceForAccount(%d)", account]] toUInt32];
}

- (NSString *)getLabelForAccount:(int)account
{
    if (![self isInitialized]) {
        return nil;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.getLabelForAccount(%d)", account]] toString];
}

- (void)setLabelForAccount:(int)account label:(NSString *)label
{
    if ([self isInitialized] && [app checkInternetConnection]) {
        self.isSyncing = YES;
        [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
        
        [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.setLabelForAccount(%d, \"%@\")", account, [label escapeStringForJS]]];
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
            [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.createAccount(\"%@\")", [label escapeStringForJS]]];
        });
    }
}

- (NSString *)getReceiveAddressForAccount:(int)account
{
    if (![self isInitialized]) {
        return nil;
    }
    
    return [[self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.getReceivingAddressForAccount(%d)", account]] toString];
}

- (void)setPbkdf2Iterations:(int)iterations
{
    DLog(@"Setting PBKDF2 Iterations");
    
    [self.context evaluateScript:[NSString stringWithFormat:@"MyWalletPhone.setPbkdf2Iterations(%d)", iterations]];
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

- (void)crypto_scrypt:(id)_password salt:(id)salt n:(NSNumber*)N r:(NSNumber*)r p:(NSNumber*)p dkLen:(NSNumber*)derivedKeyLen success:(JSValue *)_success error:(JSValue *)_error
{
    [app showBusyViewWithLoadingText:BC_STRING_DECRYPTING_PRIVATE_KEY];
    
    dispatch_async(dispatch_get_global_queue( DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        NSData * data = [self _internal_crypto_scrypt:_password salt:salt n:[N unsignedLongLongValue] r:[r unsignedIntegerValue] p:[p unsignedIntegerValue] dkLen:[derivedKeyLen unsignedIntegerValue]];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (data) {
                [_success callWithArguments:@[[data hexadecimalString]]];
            } else {
                [app hideBusyView];
                [_error callWithArguments:@[@"Scrypt Error"]];
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
        [UncaughtExceptionHandler logException:exception walletIsLoaded:[self.context isLoaded] walletIsInitialized:[self isInitialized]];
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
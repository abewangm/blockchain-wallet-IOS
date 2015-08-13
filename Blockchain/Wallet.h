/*
 * 
 * Copyright (c) 2012, Ben Reeves. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

#import "JSBridgeWebView.h"
#import "MultiAddressResponse.h"


@interface transactionProgressListeners : NSObject
@property(nonatomic, copy) void (^on_start)();
@property(nonatomic, copy) void (^on_begin_signing)();
@property(nonatomic, copy) void (^on_sign_progress)(int input);
@property(nonatomic, copy) void (^on_finish_signing)();
@property(nonatomic, copy) void (^on_success)();
@property(nonatomic, copy) void (^on_error)(NSString*error);
@end

@interface Key : NSObject {
    int tag;
}
@property(nonatomic, strong) NSString *addr;
@property(nonatomic, strong) NSString *priv;
@property(nonatomic, strong) NSString *label;
@property(nonatomic, assign) int tag;
@end

@class Wallet;

@protocol WalletDelegate <NSObject>
@optional
- (void)didSetLatestBlock:(LatestBlock*)block;
- (void)didGetMultiAddressResponse:(MultiAddressResponse*)response;
- (void)walletDidDecrypt;
- (void)walletFailedToDecrypt;
- (void)walletDidLoad;
- (void)walletFailedToLoad;
- (void)walletDidFinishLoad;
- (void)didBackupWallet;
- (void)didFailBackupWallet;
- (void)walletJSReady;
- (void)didGenerateNewAddress:(NSString *)address;
- (void)didParsePairingCode:(NSDictionary *)dict;
- (void)errorParsingPairingCode:(NSString *)message;
- (void)didCreateNewAccount:(NSString *)guid sharedKey:(NSString *)sharedKey password:(NSString *)password;
- (void)errorCreatingNewAccount:(NSString *)message;
- (void)askForPrivateKey:(NSString *)address success:(void(^)(id))_success error:(void(^)(id))_error;
- (void)didFailPutPin:(NSString *)value;
- (void)didPutPinSuccess:(NSDictionary *)dictionary;
- (void)didFailGetPinTimeout;
- (void)didFailGetPinNoResponse;
- (void)didFailGetPinInvalidResponse;
- (void)didGetPinSuccess:(NSDictionary *)dictionary;
@end

@interface Wallet : NSObject <UIWebViewDelegate, JSBridgeWebViewDelegate> {
}

// Core Wallet Init Properties
@property(nonatomic, strong) NSString *guid;
@property(nonatomic, strong) NSString *sharedKey;
@property(nonatomic, strong) NSString *password;

@property(nonatomic, strong) id<WalletDelegate> delegate;
@property(nonatomic, strong) JSBridgeWebView *webView;

@property(nonatomic) uint64_t final_balance;
@property(nonatomic) uint64_t total_sent;
@property(nonatomic) uint64_t total_received;

@property(nonatomic, strong) NSMutableDictionary *transactionProgressListeners;

// HD properties:
@property NSString *recoveryPhrase;

- (id)init;

- (void)loadWalletWithGuid:(NSString *)_guid sharedKey:(NSString *)_sharedKey password:(NSString *)_password;
- (void)loadBlankWallet;

- (NSDictionary *)addressBook;

- (void)setLabel:(NSString *)label forLegacyAddress:(NSString *)address;

- (void)loadWalletLogin;

- (void)archiveLegacyAddress:(NSString *)address;
- (void)unArchiveLegacyAddress:(NSString *)address;

- (void)sendPaymentFromAddress:(NSString*)fromAddress toAddress:(NSString*)toAddress satoshiValue:(NSString*)satoshiValue listener:(transactionProgressListeners*)listener;
- (void)sendPaymentFromAddress:(NSString*)fromAddress toAccount:(int)toAccount satoshiValue:(NSString *)satoshiValue listener:(transactionProgressListeners*)listener;
- (void)sendPaymentFromAccount:(int)fromAccount toAddress:(NSString*)toAddress satoshiValue:(NSString *)satoshiValue listener:(transactionProgressListeners*)listener;
- (void)sendPaymentFromAccount:(int)fromAccount toAccount:(int)toAccount satoshiValue:(NSString *)satoshiValue listener:(transactionProgressListeners*)listener;

- (NSString *)labelForLegacyAddress:(NSString *)address;
- (Boolean)isArchived:(NSString*)address;

- (void)addToAddressBook:(NSString *)address label:(NSString *)label;

- (BOOL)isValidAddress:(NSString *)string;
- (BOOL)isWatchOnlyLegacyAddress:(NSString*)address;

- (void)cancelTxSigning;

- (BOOL)addKey:(NSString *)privateKeyString;

// Fetch String Array Of Addresses
- (NSArray *)activeLegacyAddresses;
- (NSArray *)allLegacyAddresses;
- (NSArray *)archivedLegacyAddresses;

- (BOOL)isInitialized;
- (BOOL)hasEncryptedWalletData;

- (CGFloat)getStrengthForPassword:(NSString *)password;

- (BOOL)needsSecondPassword;
- (BOOL)validateSecondPassword:(NSString *)secondPassword;

- (void)getHistory;
- (void)getWalletAndHistory;

- (uint64_t)getLegacyAddressBalance:(NSString *)address;
- (uint64_t)parseBitcoinValue:(NSString *)input;

- (void)changeLocalCurrency:(NSString *)currencyCode;
- (void)changeBtcCurrency:(NSString *)btcCode;

- (void)clearLocalStorage;

- (void)parsePairingCode:(NSString *)code;

- (NSString *)detectPrivateKeyFormat:(NSString *)privateKeyString;

- (void)newAccount:(NSString *)password email:(NSString *)email;

- (void)pinServerPutKeyOnPinServerServer:(NSString *)key value:(NSString *)value pin:(NSString *)pin;
- (void)apiGetPINValue:(NSString *)key pin:(NSString *)pin;

- (NSString *)encrypt:(NSString *)data password:(NSString *)password pbkdf2_iterations:(int)pbkdf2_iterations;
- (NSString *)decrypt:(NSString *)data password:(NSString *)password pbkdf2_iterations:(int)pbkdf2_iterations;

- (NSString *)scorePassword:(NSString *)passwordString;

// HD Wallet
- (void)whitelistWallet;
- (void)upgradeToHDWallet;
- (Boolean)didUpgradeToHd;
- (void)getRecoveryPhrase:(NSString *)secondPassword;
- (BOOL)isRecoveryPhraseVerified;
- (void)markRecoveryPhraseVerified;
- (int)getDefaultAccountIndex;
- (int)getAccountsCount;
- (BOOL)hasLegacyAddresses;

- (uint64_t)getTotalBalanceForActiveLegacyAddresses;
- (uint64_t)getBalanceForAccount:(int)account;

- (NSString *)getLabelForAccount:(int)account;
- (void)setLabelForAccount:(int)account label:(NSString *)label;

- (void)createAccountWithLabel:(NSString *)label;

- (NSString *)getReceiveAddressForAccount:(int)account;

- (void)setPbkdf2Iterations:(int)iterations;

- (uint64_t)recommendedTransactionFeeForAddress:(NSString*)address amount:(uint64_t)amount;
- (uint64_t)recommendedTransactionFeeForAccount:(int)account amount:(uint64_t)amount;

- (uint64_t)testFeeFromAddress:(NSString *)fromAddress toAccount:(int)toAccount amountString:(NSString *)amountString;
- (uint64_t)testFeeFromAddress:(NSString *)fromAddress toAddress:(NSString *)toAddress amountString:(NSString *)amountString;
- (uint64_t)testFeeFromAccount:(int)fromAccount toAddress:(NSString *)toAddress amountString:(NSString *)amountString;
- (uint64_t)testFeeFromAccount:(int)fromAccount toAccount:(int)toAccount amountString:(NSString *)amountString;

- (void)loading_start_get_history;
- (void)loading_start_import_private_key;
- (void)loading_start_upgrade_to_hd;
- (void)loading_stop;
- (void)upgrade_success;

// Settings
- (void)getAccountInfo;
- (void)changeEmail:(NSString *)newEmailString;
- (void)resendVerificationEmail:(NSString *)emailString;
- (void)verifyEmailWithCode:(NSString *)codeString;
- (void)getAllCurrencySymbols;

@end

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
- (void)didGenerateNewAddress;
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
- (void)didGetPinResponse:(NSDictionary *)dictionary;
- (void)didImportPrivateKey:(NSString *)address;
- (void)didImportIncorrectPrivateKey:(NSString *)address;
- (void)didImportPrivateKeyToLegacyAddress;
- (void)didFailToImportPrivateKey:(NSString *)error;
- (void)didFailRecovery;
- (void)didRecoverWallet;
- (void)didFailGetHistory:(NSString *)error;
- (void)resendTwoFactorSuccess;
- (void)resendTwoFactorError:(NSString *)error;
- (void)didFailToImportPrivateKeyForWatchOnlyAddress:(NSString *)error;
- (void)returnToAddressesScreen;
- (void)alertUserOfInvalidAccountName;
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

@property(nonatomic) NSDictionary *accountInfo;

@property(nonatomic) NSString *lastScannedWatchOnlyAddress;

// HD properties:
@property NSString *recoveryPhrase;
@property int emptyAccountIndex;
@property int recoveredAccountIndex;

@property BOOL didPairAutomatically;
@property BOOL isSyncing;
@property BOOL isNew;
@property NSString *twoFactorInput;
@property (nonatomic) NSDictionary *currencySymbols;

- (id)init;

- (void)loadWalletWithGuid:(NSString *)_guid sharedKey:(NSString *)_sharedKey password:(NSString *)_password;
- (void)loadBlankWallet;

- (NSDictionary *)addressBook;

- (void)setLabel:(NSString *)label forLegacyAddress:(NSString *)address;

- (void)loadWalletLogin;

- (void)toggleArchiveLegacyAddress:(NSString *)address;
- (void)toggleArchiveAccount:(int)account;

- (void)sendPaymentWithListener:(transactionProgressListeners*)listener;

- (NSString *)labelForLegacyAddress:(NSString *)address;
- (Boolean)isAddressArchived:(NSString *)address;

- (void)addToAddressBook:(NSString *)address label:(NSString *)label;

- (BOOL)isBitcoinAddress:(NSString *)string;
- (BOOL)isWatchOnlyLegacyAddress:(NSString*)address;

- (void)cancelTxSigning;

- (BOOL)addKey:(NSString *)privateKeyString;
- (BOOL)addKey:(NSString*)privateKeyString toWatchOnlyAddress:(NSString *)watchOnlyAddress;

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
- (void)resendTwoFactorSMS;

- (NSString *)detectPrivateKeyFormat:(NSString *)privateKeyString;

- (void)newAccount:(NSString *)password email:(NSString *)email;

- (void)pinServerPutKeyOnPinServerServer:(NSString *)key value:(NSString *)value pin:(NSString *)pin;
- (void)apiGetPINValue:(NSString *)key pin:(NSString *)pin;

- (NSString *)encrypt:(NSString *)data password:(NSString *)password pbkdf2_iterations:(int)pbkdf2_iterations;
- (NSString *)decrypt:(NSString *)data password:(NSString *)password pbkdf2_iterations:(int)pbkdf2_iterations;

// HD Wallet
- (void)upgradeToHDWallet;
- (Boolean)hasAccount;
- (Boolean)didUpgradeToHd;
- (void)getRecoveryPhrase:(NSString *)secondPassword;
- (BOOL)isRecoveryPhraseVerified;
- (void)markRecoveryPhraseVerified;
- (int)getDefaultAccountIndexActiveOnly:(BOOL)isActiveOnly;
- (void)setDefaultAccount:(int)index;
- (int)getActiveAccountsCount;
- (int)getAllAccountsCount;
- (BOOL)hasLegacyAddresses;
- (Boolean)isAccountArchived:(int)account;
- (BOOL)isAccountNameValid:(NSString *)name;

- (uint64_t)getTotalActiveBalance;
- (uint64_t)getTotalBalanceForActiveLegacyAddresses;
- (uint64_t)getBalanceForAccount:(int)account activeOnly:(BOOL)isActiveOnly;

- (NSString *)getLabelForAccount:(int)account activeOnly:(BOOL)isActiveOnly;
- (void)setLabelForAccount:(int)account activeOnly:(BOOL)isActiveOnly label:(NSString *)label;

- (void)createAccountWithLabel:(NSString *)label;
- (void)generateNewKey;

- (NSString *)getReceiveAddressForAccount:(int)account activeOnly:(BOOL)isActiveOnly;

- (NSString *)getXpubForAccount:(int)accountIndex;

- (void)setPbkdf2Iterations:(int)iterations;

- (void)setTransactionFee:(uint64_t)feePerKb;
- (uint64_t)getTransactionFee;

- (void)loading_start_get_history;
- (void)loading_start_import_private_key;
- (void)loading_start_upgrade_to_hd;
- (void)loading_start_recover_wallet;
- (void)loading_stop;
- (void)upgrade_success;

- (BOOL)checkIfWalletHasAddress:(NSString *)address;

- (NSDictionary *)filteredWalletJSON;

// Settings
- (void)getAccountInfo;
- (void)changeEmail:(NSString *)newEmail;
- (void)resendVerificationEmail:(NSString *)email;
- (void)getAllCurrencySymbols;
- (void)changeMobileNumber:(NSString *)newMobileNumber;
- (void)verifyMobileNumber:(NSString *)code;
- (void)updatePasswordHint:(NSString *)hint;
- (void)enableTwoStepVerificationForSMS;
- (void)disableTwoStepVerification;
- (void)changePassword:(NSString *)changedPassword;
- (BOOL)isCorrectPassword:(NSString *)inputedPassword;
- (void)enableEmailNotifications;
- (void)disableEmailNotifications;
- (void)changeTorBlocking:(BOOL)willEnable;

// Security Center
- (BOOL)hasVerifiedEmail;
- (BOOL)hasVerifiedMobileNumber;
- (BOOL)hasStoredPasswordHint;
- (BOOL)hasEnabledTwoStep;
- (BOOL)hasBlockedTorRequests;
- (int)securityCenterScore;

// Payment Spender
- (void)createNewPayment;
- (void)changePaymentFromAddress:(NSString *)fromString;
- (void)changePaymentFromAccount:(int)fromInt;
- (void)changePaymentToAccount:(int)toInt;
- (void)changePaymentToAddress:(NSString *)toString;
- (void)changePaymentAmount:(uint64_t)amount;
- (void)sweepPayment;
- (void)getPaymentFee;
- (void)resetPaymentFee;
- (void)checkIfOverspending;

// Recover with passphrase
- (void)recoverWithEmail:(NSString *)email password:(NSString *)recoveryPassword passphrase:(NSString *)passphrase;

- (void)updateServerURL:(NSString *)newURL;

@end

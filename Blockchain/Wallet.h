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

#import "MultiAddressResponse.h"
#import "SRWebSocket.h"

@interface transactionProgressListeners : NSObject
@property(nonatomic, copy) void (^on_start)();
@property(nonatomic, copy) void (^on_begin_signing)();
@property(nonatomic, copy) void (^on_sign_progress)(int input);
@property(nonatomic, copy) void (^on_finish_signing)();
@property(nonatomic, copy) void (^on_success)(NSString*secondPassword);
@property(nonatomic, copy) void (^on_error)(NSString*error, NSString*secondPassword);
@end

@interface Key : NSObject {
    int tag;
}
@property(nonatomic, strong) NSString *addr;
@property(nonatomic, strong) NSString *priv;
@property(nonatomic, strong) NSString *label;
@property(nonatomic, assign) int tag;
@end

@class Wallet, Transaction, JSValue, JSContext;

@protocol ExchangeAccountDelegate
- (void)watchPendingTrades;
- (void)fetchExchangeAccount;
@end

@protocol WalletDelegate <NSObject>
@optional
- (void)didSetLatestBlock:(LatestBlock*)block;
- (void)didGetMultiAddressResponse:(MultiAddressResponse*)response;
- (void)didFilterTransactions:(NSArray *)transactions;
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
- (void)didFailPutPin:(NSString *)value;
- (void)didPutPinSuccess:(NSDictionary *)dictionary;
- (void)didFailGetPinTimeout;
- (void)didFailGetPinNoResponse;
- (void)didFailGetPinInvalidResponse;
- (void)didGetPinResponse:(NSDictionary *)dictionary;
- (void)didImportKey:(NSString *)address;
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
- (void)alertUserOfInvalidPrivateKey;
- (void)sendFromWatchOnlyAddress;
- (void)estimateTransactionSize:(uint64_t)size;
- (void)didCheckForOverSpending:(NSNumber *)amount fee:(NSNumber *)fee;
- (void)didGetMaxFee:(NSNumber *)fee amount:(NSNumber *)amount dust:(NSNumber *)dust willConfirm:(BOOL)willConfirm;
- (void)didGetFee:(NSNumber *)fee dust:(NSNumber *)dust txSize:(NSNumber *)txSize;
- (void)didGetFeeBounds:(NSArray *)bounds confirmationEstimation:(NSNumber *)confirmationEstimation maxAmounts:(NSArray *)maxAmounts maxFees:(NSArray *)maxFees;
- (void)didChangeForcedFee:(NSNumber *)fee dust:(NSNumber *)dust;
- (void)enableSendPaymentButtons;
- (void)didGetSurgeStatus:(BOOL)surgeStatus;
- (void)updateSendBalance:(NSNumber *)balance;
- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed;
- (void)showSummaryForTransferAll;
- (void)sendDuringTransferAll:(NSString *)secondPassword;
- (void)didErrorDuringTransferAll:(NSString *)error secondPassword:(NSString *)secondPassword;
- (void)updateLoadedAllTransactions:(NSNumber *)loadedAll;
- (void)receivedTransactionMessage;
- (void)paymentReceivedOnPINScreen:(NSString *)amount;
- (void)didReceivePaymentNotice:(NSString *)notice;
- (void)didGetFiatAtTime:(NSString *)fiatAmount currencyCode:(NSString *)currencyCode;
- (void)didErrorWhenGettingFiatAtTime:(NSString *)error;
- (void)didSetDefaultAccount;
- (void)didChangeLocalCurrency;
- (void)setupBackupTransferAll:(id)transferAllController;
- (void)didCompleteTrade:(NSDictionary *)trade;
- (void)didPushTransaction;
@end

@interface Wallet : NSObject <UIWebViewDelegate, SRWebSocketDelegate, ExchangeAccountDelegate> {
}

// Core Wallet Init Properties
@property (readonly, nonatomic) JSContext *context;

@property(nonatomic, strong) NSString *guid;
@property(nonatomic, strong) NSString *sharedKey;
@property(nonatomic, strong) NSString *password;

@property(nonatomic, strong) NSString *sessionToken;

@property(nonatomic, strong) id<WalletDelegate> delegate;

@property(nonatomic) uint64_t final_balance;
@property(nonatomic) uint64_t total_sent;
@property(nonatomic) uint64_t total_received;

@property(nonatomic, strong) NSMutableDictionary *transactionProgressListeners;

@property(nonatomic) NSDictionary *accountInfo;
@property(nonatomic) BOOL hasLoadedAccountInfo;

@property(nonatomic) NSString *lastScannedWatchOnlyAddress;
@property(nonatomic) NSString *lastImportedAddress;
@property(nonatomic) BOOL didReceiveMessageForLastTransaction;

// HD properties:
@property NSString *recoveryPhrase;
@property int emptyAccountIndex;
@property int recoveredAccountIndex;

@property BOOL didPairAutomatically;
@property BOOL isFilteringTransactions;
@property BOOL isFetchingTransactions;
@property BOOL isSyncing;
@property BOOL isNew;
@property NSString *twoFactorInput;
@property (nonatomic) NSDictionary *currencySymbols;

@property (nonatomic, assign) id <SRWebSocketDelegate> socketDelegate;
@property (nonatomic) SRWebSocket *webSocket;
@property (nonatomic) NSTimer *webSocketTimer;
@property (nonatomic) NSString *swipeAddressToSubscribe;

@property (nonatomic) int lastLabelledAddressesCount;

- (id)init;

- (void)loadWalletWithGuid:(NSString *)_guid sharedKey:(NSString *)_sharedKey password:(NSString *)_password;
- (void)loadBlankWallet;

- (void)resetSyncStatus;

- (NSDictionary *)addressBook;

- (void)setLabel:(NSString *)label forLegacyAddress:(NSString *)address;

- (void)loadWalletLogin;

- (void)toggleArchiveLegacyAddress:(NSString *)address;
- (void)toggleArchiveAccount:(int)account;
- (void)archiveTransferredAddresses:(NSArray *)transferredAddresses;

- (void)sendPaymentWithListener:(transactionProgressListeners*)listener secondPassword:(NSString *)secondPassword;
- (void)sendFromWatchOnlyAddress:(NSString *)watchOnlyAddress privateKey:(NSString *)privateKeyString;

- (NSString *)labelForLegacyAddress:(NSString *)address;
- (Boolean)isAddressArchived:(NSString *)address;

- (void)subscribeToSwipeAddress:(NSString *)address;

- (void)addToAddressBook:(NSString *)address label:(NSString *)label;

- (BOOL)isBitcoinAddress:(NSString *)string;
- (BOOL)isWatchOnlyLegacyAddress:(NSString*)address;

- (BOOL)addKey:(NSString *)privateKeyString;
- (BOOL)addKey:(NSString*)privateKeyString toWatchOnlyAddress:(NSString *)watchOnlyAddress;

// Fetch String Array Of Addresses
- (NSArray *)activeLegacyAddresses;
- (NSArray *)spendableActiveLegacyAddresses;
- (NSArray *)allLegacyAddresses;
- (NSArray *)archivedLegacyAddresses;

- (BOOL)isInitialized;
- (BOOL)hasEncryptedWalletData;

- (float)getStrengthForPassword:(NSString *)password;

- (BOOL)needsSecondPassword;
- (BOOL)validateSecondPassword:(NSString *)secondPassword;

- (void)getHistory;
- (void)getHistoryIfNoTransactionMessage;
- (void)getWalletAndHistory;

- (uint64_t)getLegacyAddressBalance:(NSString *)address;
- (uint64_t)parseBitcoinValueFromTextField:(UITextField *)textField;
- (uint64_t)parseBitcoinValueFromString:(NSString *)inputString;
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

- (BOOL)isAddressAvailable:(NSString *)address;
- (BOOL)isAccountAvailable:(int)account;
- (int)getIndexOfActiveAccount:(int)account;

- (void)fetchMoreTransactions;
- (void)reloadFilter;

- (int)getAllTransactionsCount;

// HD Wallet
- (void)upgradeToV3Wallet;
- (Boolean)hasAccount;
- (Boolean)didUpgradeToHd;
- (void)getRecoveryPhrase:(NSString *)secondPassword;
- (BOOL)isRecoveryPhraseVerified;
- (void)markRecoveryPhraseVerified;
- (int)getFilteredOrDefaultAccountIndex;
- (int)getDefaultAccountIndex;
- (void)setDefaultAccount:(int)index;
- (int)getActiveAccountsCount;
- (int)getAllAccountsCount;
- (BOOL)hasLegacyAddresses;
- (Boolean)isAccountArchived:(int)account;
- (BOOL)isAccountNameValid:(NSString *)name;

- (uint64_t)getTotalActiveBalance;
- (uint64_t)getTotalBalanceForActiveLegacyAddresses;
- (uint64_t)getTotalBalanceForSpendableActiveLegacyAddresses;
- (uint64_t)getBalanceForAccount:(int)account;

- (NSString *)getLabelForAccount:(int)account;
- (void)setLabelForAccount:(int)account label:(NSString *)label;

- (void)createAccountWithLabel:(NSString *)label;
- (void)generateNewKey;

- (NSString *)getReceiveAddressOfDefaultAccount;
- (NSString *)getReceiveAddressForAccount:(int)account;

- (NSString *)getXpubForAccount:(int)accountIndex;

- (void)setPbkdf2Iterations:(int)iterations;

- (void)loading_start_get_history;
- (void)loading_start_upgrade_to_hd;
- (void)loading_start_recover_wallet;
- (void)loading_stop;
- (void)upgrade_success;

- (BOOL)checkIfWalletHasAddress:(NSString *)address;

- (NSDictionary *)filteredWalletJSON;

- (int)getDefaultAccountLabelledAddressesCount;

// Settings
- (void)getAccountInfo;
- (NSString *)getEmail;
- (NSString *)getSMSNumber;
- (BOOL)getSMSVerifiedStatus;
- (NSDictionary *)getFiatCurrencies;
- (NSDictionary *)getBtcCurrencies;
- (int)getTwoStepType;
- (BOOL)getEmailVerifiedStatus;

- (void)changeEmail:(NSString *)newEmail;
- (void)resendVerificationEmail:(NSString *)email;
- (void)getAllCurrencySymbols;
- (void)changeMobileNumber:(NSString *)newMobileNumber;
- (void)verifyMobileNumber:(NSString *)code;
- (void)enableTwoStepVerificationForSMS;
- (void)disableTwoStepVerification;
- (void)changePassword:(NSString *)changedPassword;
- (BOOL)isCorrectPassword:(NSString *)inputedPassword;
- (void)enableEmailNotifications;
- (void)disableEmailNotifications;
- (void)enableSMSNotifications;
- (void)disableSMSNotifications;
- (BOOL)emailNotificationsEnabled;
- (BOOL)SMSNotificationsEnabled;

// Security Center
- (BOOL)hasVerifiedEmail;
- (BOOL)hasVerifiedMobileNumber;
- (BOOL)hasEnabledTwoStep;
- (int)securityCenterScore;
- (int)securityCenterCompletedItemsCount;

// Payment Spender
- (void)createNewPayment;
- (void)changePaymentFromAddress:(NSString *)fromString isAdvanced:(BOOL)isAdvanced;
- (void)changePaymentFromAccount:(int)fromInt isAdvanced:(BOOL)isAdvanced;
- (void)changePaymentToAccount:(int)toInt;
- (void)changePaymentToAddress:(NSString *)toString;
- (void)changePaymentAmount:(uint64_t)amount;
- (void)sweepPaymentRegular;
- (void)sweepPaymentRegularThenConfirm;
- (void)sweepPaymentAdvanced:(uint64_t)fee;
- (void)sweepPaymentAdvancedThenConfirm:(uint64_t)fee;
- (void)setupBackupTransferAll:(id)transferAllController;
- (void)getInfoForTransferAllFundsToAccount;
- (void)setupFirstTransferForAllFundsToAccount:(int)account address:(NSString *)address secondPassword:(NSString *)secondPassword useSendPayment:(BOOL)useSendPayment;
- (void)setupFollowingTransferForAllFundsToAccount:(int)account address:(NSString *)address secondPassword:(NSString *)secondPassword useSendPayment:(BOOL)useSendPayment;
- (void)transferFundsBackupWithListener:(transactionProgressListeners*)listener secondPassword:(NSString *)secondPassword;
- (void)transferFundsToDefaultAccountFromAddress:(NSString *)address;
- (void)checkIfOverspending;
- (void)getFeeBounds:(uint64_t)fee;
- (void)changeForcedFee:(uint64_t)fee;
- (void)getTransactionFee;
- (void)getSurgeStatus;
- (uint64_t)dust;
- (void)incrementReceiveIndexOfDefaultAccount;

// Recover with passphrase
- (void)recoverWithEmail:(NSString *)email password:(NSString *)recoveryPassword passphrase:(NSString *)passphrase;

- (void)updateServerURL:(NSString *)newURL;

// Transaction Details
- (void)saveNote:(NSString *)note forTransaction:(NSString *)hash;
- (void)getFiatAtTime:(uint64_t)time value:(int64_t)value currencyCode:(NSString *)currencyCode;
- (NSString *)getNotePlaceholderForTransaction:(Transaction *)transaction filter:(NSInteger)filter;

- (JSValue *)executeJSSynchronous:(NSString *)command;

@end

//
//  TransactionDetailViewModel.m
//  Blockchain
//
//  Created by kevinwu on 9/7/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailViewModel.h"
#import "ContactTransaction.h"
#import "Transaction.h"
#import "EtherTransaction.h"
#import "NSNumberFormatter+Currencies.h"
@interface TransactionDetailViewModel ()
@property (nonatomic) NSString *amountString;
@property (nonatomic) uint64_t feeInSatoshi;
@property (nonatomic) NSString *feeString;
@end
@implementation TransactionDetailViewModel

- (id)initWithTransaction:(Transaction *)transaction
{
    if (self == [super init]) {
        self.assetType = AssetTypeBitcoin;
        self.fromString = [transaction.from objectForKey:DICTIONARY_KEY_LABEL];
        self.fromAddress = [transaction.from objectForKey:DICTIONARY_KEY_ADDRESS];
        self.fromWithinWallet = [transaction.from objectForKey:DICTIONARY_KEY_ACCOUNT_INDEX] || ![[transaction.from objectForKey:DICTIONARY_KEY_LABEL] isEqualToString:self.fromAddress];
        self.to = transaction.to;
        self.toString = [transaction.to.firstObject objectForKey:DICTIONARY_KEY_LABEL];
        self.amountInSatoshi = ABS(transaction.amount);
        self.feeInSatoshi = transaction.fee;
        self.txType = transaction.txType;
        self.time = transaction.time;
        self.note = transaction.note;
        self.confirmations = [NSString stringWithFormat:@"%u/%u", transaction.confirmations, kConfirmationBitcoinThreshold];
        self.confirmed = transaction.confirmations >= kConfirmationBitcoinThreshold;
        self.fiatAmountsAtTime = transaction.fiatAmountsAtTime;
        self.doubleSpend = transaction.doubleSpend;
        self.replaceByFee = transaction.replaceByFee;
        self.dateString = [self getDate];
        self.myHash = transaction.myHash;
        
        if ([transaction isMemberOfClass:[ContactTransaction class]]) {
            ContactTransaction *contactTransaction = (ContactTransaction *)transaction;
            self.isContactTransaction = YES;
            self.reason = contactTransaction.reason;
        };
        self.contactName = transaction.contactName;
        self.detailButtonTitle = [[NSString stringWithFormat:@"%@ %@",BC_STRING_VIEW_ON_URL_ARGUMENT, HOST_NAME_WALLET_SERVER] uppercaseString];
        self.detailButtonLink = [URL_SERVER stringByAppendingFormat:@"/tx/%@", self.myHash];
    }
    return self;
}

- (id)initWithEtherTransaction:(EtherTransaction *)etherTransaction exchangeRate:(NSDecimalNumber *)exchangeRate
{
    if (self == [super init]) {
        self.assetType = AssetTypeEther;
        self.txType = etherTransaction.txType;
        self.fromString = etherTransaction.from;
        self.to = @[etherTransaction.to];
        self.toString = etherTransaction.to;
        self.amountString = etherTransaction.amount;
        self.myHash = etherTransaction.myHash;
        self.feeString = etherTransaction.fee;
        self.note = etherTransaction.note;
        self.time = etherTransaction.time;
        self.dateString = [self getDate];
        self.detailButtonTitle = [[NSString stringWithFormat:@"%@ %@",BC_STRING_VIEW_ON_URL_ARGUMENT, HOST_NAME_ETHERSCAN] uppercaseString];
        self.detailButtonLink = [URL_ETHERSCAN stringByAppendingFormat:@"/tx/%@", self.myHash];
        self.ethExchangeRate = exchangeRate;
        self.confirmations = [NSString stringWithFormat:@"%lld/%u", etherTransaction.confirmations, kConfirmationEtherThreshold];
        self.confirmed = etherTransaction.confirmations >= kConfirmationEtherThreshold;
    }
    return self;
}

- (NSString *)getDate
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setAMSymbol:@"am"];
    [dateFormatter setPMSymbol:@"pm"];
    [dateFormatter setDateFormat:@"MMMM dd, yyyy @ h:mmaa"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:self.time];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

- (NSString *)getAmountString
{
    if (self.assetType == AssetTypeBitcoin) {
        return [NSNumberFormatter formatMoneyWithLocalSymbol:ABS(self.amountInSatoshi)];
    } else if (self.assetType == AssetTypeEther) {
        return [NSNumberFormatter formatEthWithLocalSymbol:self.amountString exchangeRate:self.ethExchangeRate];
    }
    return nil;
}

- (NSString *)getFeeString
{
    if (self.assetType == AssetTypeBitcoin) {
        return [NSNumberFormatter formatMoneyWithLocalSymbol:ABS(self.feeInSatoshi)];
    } else if (self.assetType == AssetTypeEther) {
        return self.amountString;
    }
    return nil;
}

@end

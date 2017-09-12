//
//  TransactionDetailViewModel.h
//  Blockchain
//
//  Created by kevinwu on 9/7/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//
#import <Foundation/Foundation.h>
#import "Assets.h"
@class Transaction, EtherTransaction;

@interface TransactionDetailViewModel : NSObject
@property (nonatomic) AssetType assetType;
@property (nonatomic) NSString *fromString;
@property (nonatomic) NSString *fromAddress;
@property (nonatomic) BOOL fromWithinWallet;
@property (nonatomic) NSArray *to;
@property (nonatomic) NSString *toString;
@property (nonatomic) uint64_t amountInSatoshi;
@property (nonatomic) NSString *txType;
@property (nonatomic) NSString *txDescription;
@property (nonatomic) NSString *dateString;
@property (nonatomic) NSString *status;
@property (nonatomic) NSString *myHash;
@property (nonatomic) NSString *note;
@property (nonatomic) uint64_t time;
@property (nonatomic) NSString *detailButtonTitle;
@property (nonatomic) NSString *detailButtonLink;
@property (nonatomic) NSMutableDictionary *fiatAmountsAtTime;
@property (nonatomic) BOOL doubleSpend;
@property (nonatomic) BOOL replaceByFee;
@property (nonatomic) uint32_t confirmations;

@property (nonatomic) BOOL isContactTransaction;
@property (nonatomic) NSString *reason;
@property (nonatomic) NSString *contactName;

- (id)initWithTransaction:(Transaction *)transaction;
- (id)initWithEtherTransaction:(EtherTransaction *)etherTransaction;
- (NSString *)getAmountString;
- (NSString *)getFeeString;
@end

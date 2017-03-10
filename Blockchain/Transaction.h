//
//  Transaction.h
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Blockchain Luxembourg S.A. All rights reserved.
//

#import "InOut.h"

@interface Transaction : NSObject

+ (Transaction *)fromJSONDict:(NSDictionary *)dict;

@property(nonatomic, assign) uint32_t block_height;
@property(nonatomic, assign) uint32_t confirmations;
@property(nonatomic, assign) int64_t fee;
@property(nonatomic, strong) NSString *myHash;
@property(nonatomic, strong) NSString *txType;
@property(nonatomic, strong) NSString *note;
@property(nonatomic, assign) int64_t amount;
@property(nonatomic, assign) uint32_t size;
@property(nonatomic, assign) uint64_t time;
@property(nonatomic, assign) uint32_t tx_index;
@property(nonatomic, assign) BOOL fromWatchOnly;
@property(nonatomic, assign) BOOL toWatchOnly;
@property(nonatomic, assign) BOOL doubleSpend;
@property(nonatomic, assign) BOOL replaceByFee;
@property(nonatomic, strong) NSMutableDictionary *fiatAmountsAtTime;

@property(nonatomic, strong) InOut *from;
@property(nonatomic, strong) NSArray *to;

- (NSString *)getDate;

@end

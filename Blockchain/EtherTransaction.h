//
//  EtherTransaction.h
//  Blockchain
//
//  Created by kevinwu on 8/30/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface EtherTransaction : NSObject

+ (EtherTransaction *)fromJSONDict:(NSDictionary *)dict;

@property (nonatomic) NSString *amount;
@property (nonatomic) NSString *fee;
@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;
@property (nonatomic) NSString *myHash;

@end

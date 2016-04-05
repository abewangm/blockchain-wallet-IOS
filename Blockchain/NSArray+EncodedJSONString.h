//
//  NSArray+EncodedJSONString.h
//  Blockchain
//
//  Created by Kevin Wu on 4/5/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSArray (EncodedJSONString)
- (NSString *)jsonString;
- (NSString *)encodedJSONString;
@end

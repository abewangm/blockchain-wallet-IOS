//
//  NSURLSession+SendSynchronousRequest.h
//  Blockchain
//
//  Created by Kevin Wu on 8/25/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface NSURLSession (SendSynchronousRequest)

+ (NSData *)sendSynchronousRequest:(NSURLRequest *)request
                          delegate:(id <NSURLSessionDelegate>)delegate
                 returningResponse:(__autoreleasing NSURLResponse **)responsePtr
                             error:(__autoreleasing NSError **)errorPtr;
@end

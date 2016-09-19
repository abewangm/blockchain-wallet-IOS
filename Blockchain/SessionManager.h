//
//  SessionManager.h
//  Blockchain
//
//  Created by Kevin Wu on 8/30/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SessionManager : NSObject

+ (void)setupSharedSessionConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id<NSURLSessionDelegate>)delegate queue:(NSOperationQueue *)queue;
+ (NSURLSession *)sharedSession;
+ (void)resetSessionWithCompletionHandler:(void (^)(void))completionHandler;

@end

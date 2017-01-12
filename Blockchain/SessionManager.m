//
//  SessionManager.m
//  Blockchain
//
//  Created by Kevin Wu on 8/30/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SessionManager.h"

@implementation SessionManager

static NSURLSession *sharedSession = nil;

+ (void)setupSharedSessionConfiguration:(NSURLSessionConfiguration *)configuration delegate:(id<NSURLSessionDelegate>)delegate queue:(NSOperationQueue *)queue
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedSession = [NSURLSession sessionWithConfiguration:configuration delegate:delegate delegateQueue:queue];
    });
}

+ (NSURLSession *)sharedSession
{
    if (sharedSession == nil) {
        NSLog(@"SessionManager error: sharedSession called before setup!");
    }
    return sharedSession;
}

+ (void)resetSessionWithCompletionHandler:(void (^)(void))completionHandler;
{
    if (sharedSession == nil) {
        NSLog(@"SessionManager error: resetSessionWithCompletionHandler: called before setup!");
    }
    [sharedSession resetWithCompletionHandler:completionHandler];
}

@end

//
//  AppDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 05/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "RootService.h"
#import "Wallet.h"
#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark - Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [app application:application didFinishLaunchingWithOptions:launchOptions];
    return YES;
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    [app applicationDidBecomeActive:application];
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    [app applicationWillResignActive:application];
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [app applicationDidEnterBackground:application];
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    [app applicationWillEnterForeground:application];
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    [app application:application handleOpenURL:url];
    return YES;
}

@end

//
//  AppDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 05/01/2012.
//  Copyright (c) 2012 Blockchain Luxembourg S.A. All rights reserved.
//

#import "RootService.h"
#import "AppDelegate.h"

@implementation AppDelegate

#pragma mark - Lifecycle

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    return [app application:application didFinishLaunchingWithOptions:launchOptions];
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
    return [app application:application handleOpenURL:url];
}

@end

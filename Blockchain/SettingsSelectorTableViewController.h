//
//  SettingsSelectorTableViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 7/14/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "AppDelegate.h"

@protocol CurrencySelectorDelegate <NSObject>
-(void)changeLocalCurrencySuccess;
@end

@interface SettingsSelectorTableViewController : UITableViewController
@property (nonatomic) id <CurrencySelectorDelegate> delegate;
@property (nonatomic, copy) NSDictionary *itemsDictionary;
@property (nonatomic, copy) NSDictionary *allCurrencySymbolsDictionary;
@end

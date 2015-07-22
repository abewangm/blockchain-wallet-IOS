//
//  SettingsBitcoinUnitTableViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 7/22/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol CurrencySelectorDelegate <NSObject>
-(void)changeLocalCurrencySuccess;
@end

@interface SettingsBitcoinUnitTableViewController : UITableViewController
@property (nonatomic) id <CurrencySelectorDelegate> delegate;
@property (nonatomic, copy) NSDictionary *itemsDictionary;
@end

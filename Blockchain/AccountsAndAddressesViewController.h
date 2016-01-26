//
//  AccountsAndAddressesViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 1/12/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AccountsAndAddressesViewController : UIViewController
@property (nonatomic) UITableView *tableView;
@property(nonatomic, strong) NSArray *allKeys;

@end

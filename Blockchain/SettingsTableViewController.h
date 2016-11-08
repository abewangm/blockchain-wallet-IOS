//
//  SettingsTableViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 7/13/15.
//  Copyright (c) 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsTableViewController : UITableViewController
@property (weak, nonatomic) UIViewController *alertTargetViewController;

- (void)reload;

- (void)verifyEmailTapped;
- (void)linkMobileTapped;
- (void)changeTwoStepTapped;

@end

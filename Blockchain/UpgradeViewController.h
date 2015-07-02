//
//  UpgradeViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 7/1/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef void (^ContinueUpgradeBlock)();

@interface UpgradeViewController : UIViewController <UIScrollViewDelegate>

// Must set this block to execute actual upgrade
@property (nonatomic, copy) ContinueUpgradeBlock continueUpgradeBlock;

@end

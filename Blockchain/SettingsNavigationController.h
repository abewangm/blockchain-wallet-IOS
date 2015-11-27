//
//  SettingsNavigationController.h
//  Blockchain
//
//  Created by Kevin Wu on 7/13/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsNavigationController : UINavigationController
@property (nonatomic) UILabel *headerLabel;
- (void)reload;
@end

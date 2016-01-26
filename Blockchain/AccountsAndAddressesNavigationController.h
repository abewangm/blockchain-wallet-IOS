//
//  AccountsAndAddressesNavigationController.h
//  Blockchain
//
//  Created by Kevin Wu on 1/12/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCFadeView.h"

@interface AccountsAndAddressesNavigationController : UINavigationController
@property (nonatomic) UILabel *headerLabel;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) BCFadeView *busyView;

- (void)reload;

@end

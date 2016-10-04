//
//  AccountsAndAddressesNavigationController.h
//  Blockchain
//
//  Created by Kevin Wu on 1/12/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCFadeView.h"

@interface AccountsAndAddressesNavigationController : UINavigationController <TopViewController>
@property (nonatomic) UILabel *headerLabel;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) UIButton *warningButton;
@property (nonatomic) BCFadeView *busyView;
@property (nonatomic) UILabel *busyLabel;

- (void)didGenerateNewAddress;
- (void)reload;
- (void)alertUserToTransferAllFunds:(BOOL)automaticallyShown;

@end

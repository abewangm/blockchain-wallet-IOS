//
//  AccountsAndAddressesNavigationController.h
//  Blockchain
//
//  Created by Kevin Wu on 1/12/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCFadeView.h"

@protocol TopViewController <NSObject>
- (void)showBusyViewWithLoadingText:(NSString *)text;
- (void)updateBusyViewLoadingText:(NSString *)text;
- (void)hideBusyView;
- (void)presentAlertController:(UIAlertController *)alertController;
@end

@interface AccountsAndAddressesNavigationController : UINavigationController <TopViewController>
@property (nonatomic) UILabel *headerLabel;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) BCFadeView *busyView;
@property (nonatomic) UILabel *busyLabel;

- (void)didGenerateNewAddress;
- (void)reload;

@end

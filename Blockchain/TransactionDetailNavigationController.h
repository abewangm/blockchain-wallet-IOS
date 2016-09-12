//
//  TransactionDetailNavigationController.h
//  Blockchain
//
//  Created by Kevin Wu on 9/2/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "BCFadeView.h"

@interface TransactionDetailNavigationController : UINavigationController
@property (nonatomic) BCFadeView *busyView;
@property (nonatomic) UIButton *backButton;
@property (nonatomic) UIButton *closeButton;
@property (nonatomic) UILabel *headerLabel;

@end

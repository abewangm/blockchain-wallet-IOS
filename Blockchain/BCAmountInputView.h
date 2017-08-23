//
//  BCAmountView.h
//  Blockchain
//
//  Created by kevinwu on 8/23/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BCAmountInputView : UIView
@property (nonatomic) UILabel *btcLabel;
@property (nonatomic) UILabel *fiatLabel;
@property (nonatomic) UITextField *btcField;
@property (nonatomic) UITextField *fiatField;
- (void)hideKeyboard;
// Input accessory view needs to be configured
// Text field delegate needs to be configured
// 

@end

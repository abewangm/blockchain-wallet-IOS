//
//  BCEditAccountView.h
//  Blockchain
//
//  Created by Mark Pfluger on 12/1/14.
//  Copyright (c) 2014 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BCSecureTextField;

@interface BCEditAccountView : UIView <UITextFieldDelegate>

@property int accountIdx;
@property (nonatomic, strong) BCSecureTextField *labelTextField;

@end

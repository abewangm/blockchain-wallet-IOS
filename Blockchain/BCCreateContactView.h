//
//  BCCreateContactView.h
//  Blockchain
//
//  Created by Kevin Wu on 11/7/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BCSecureTextField;

@interface BCCreateContactView : UIView <UITextFieldDelegate>
@property (nonatomic, strong) BCSecureTextField *nameField;
@property (nonatomic, strong) BCSecureTextField *idField;
@end

//
//  BCEditAddressView.h
//  Blockchain
//
//  Created by Kevin Wu on 1/29/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BCTextField;

@interface BCEditAddressView : UIView <UITextFieldDelegate>

@property NSString *address;
@property (nonatomic) BCTextField *labelTextField;

-(id)initWithAddress:(NSString *)address;

@end

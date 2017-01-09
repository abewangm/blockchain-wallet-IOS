//
//  BCCreateContactView.h
//  Blockchain
//
//  Created by Kevin Wu on 11/7/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BCSecureTextField;

@protocol CreateContactDelegate
- (void)didCreateContactName:(NSString *)name;
- (void)didCreateSenderName:(NSString *)senderName contactName:(NSString *)contactName;

- (void)didSelectQRCode;
- (void)didSelectShareLink;

- (void)dismissContactController;
@end

@interface BCCreateContactView : UIView <UITextFieldDelegate>
@property (nonatomic, strong) BCSecureTextField *textField;
@property (nonatomic) id<CreateContactDelegate> delegate;
- (id)initWithContactName:(NSString *)contactName senderName:(NSString *)senderName;

@end

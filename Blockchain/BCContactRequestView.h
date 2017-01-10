//
//  BCContactRequestView.h
//  Blockchain
//
//  Created by kevinwu on 1/9/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BCSecureTextField;

@protocol ContactRequestDelegate
- (void)promptSendAmount:(NSString *)reason;
- (void)promptRequestAmount:(NSString *)reason;
- (void)createSendRequestWithReason:(NSString *)reason amount:(uint64_t)amount;
- (void)createReceiveRequestWithReason:(NSString *)reason amount:(uint64_t)amount;
@end

@interface BCContactRequestView : UIView <UITextFieldDelegate>
@property (nonatomic, strong) BCSecureTextField *textField;
@property (nonatomic) id<ContactRequestDelegate> delegate;
@property (nonatomic, readonly) BOOL willSend;

- (id)initWithContactName:(NSString *)name reason:(NSString *)reason willSend:(BOOL)willSend;
- (void)showKeyboard;

@end

//
//  BCContactRequestView.h
//  Blockchain
//
//  Created by kevinwu on 1/9/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class BCSecureTextField, Contact;

typedef enum {
    RequestTypeSendReason,
    RequestTypeReceiveReason,
    RequestTypeSendAmount,
    RequestTypeReceiveAmount
} RequestType;

@protocol ContactRequestDelegate
- (void)promptSendAmount:(NSString *)reason forContact:(Contact *)contact;
- (void)promptRequestAmount:(NSString *)reason forContact:(Contact *)contact;
- (void)createSendRequestForContact:(Contact *)contact withReason:(NSString *)reason amount:(uint64_t)amount;
- (void)createReceiveRequestForContact:(Contact *)contact withReason:(NSString *)reason amount:(uint64_t)amount;
@end

@interface BCContactRequestView : UIView <UITextFieldDelegate>
@property (nonatomic, strong) BCSecureTextField *textField;
@property (nonatomic) id<ContactRequestDelegate> delegate;
@property (nonatomic, readonly) BOOL willSend;

- (id)initWithContact:(Contact *)contact reason:(NSString *)reason willSend:(BOOL)willSend;
- (void)showKeyboard;

@end

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
- (void)createSendRequestForContact:(Contact *)contact withReason:(NSString *)reason amount:(uint64_t)amount lastSelectedField:(UITextField *)textField accountOrAddress:(id)accountOrAddress;
- (void)createReceiveRequestForContact:(Contact *)contact withReason:(NSString *)reason amount:(uint64_t)amount lastSelectedField:(UITextField *)textField;
@end

@interface BCContactRequestView : UIView <UITextFieldDelegate>
@property (nonatomic, strong) BCSecureTextField *descriptionField;
@property (nonatomic) id<ContactRequestDelegate> delegate;
@property (nonatomic, readonly) BOOL willSend;

- (id)initWithContact:(Contact *)contact amount:(uint64_t)amount willSend:(BOOL)willSend accountOrAddress:(id)accountOrAddress;

@end

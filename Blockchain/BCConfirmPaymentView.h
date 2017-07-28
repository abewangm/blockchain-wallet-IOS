//
//  BCConfirmPaymentView.h
//  Blockchain
//
//  Created by Kevin Wu on 10/2/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@class ContactTransaction;

typedef enum {
    RejectionTypeDecline,
    RejectionTypeCancel
} RejectionType;

@protocol ConfirmPaymentViewDelegate
- (void)setupNoteForTransaction:(NSString *)note;
- (void)feeInformationButtonClicked;
- (void)confirmRejectPayment:(RejectionType)rejectionType;
@end
@interface BCConfirmPaymentView : UIView

- (id)initWithWindow:(UIView *)window
                from:(NSString *)from
                  To:(NSString *)to
              amount:(uint64_t)amount
                 fee:(uint64_t)fee
               total:(uint64_t)total
         contactTransaction:(ContactTransaction *)contactTransaction
               surge:(BOOL)surgePresent;

@property (nonatomic) UIButton *reallyDoPaymentButton;
@property (nonatomic) UIButton *feeInformationButton;

@property (weak, nonatomic) id <ConfirmPaymentViewDelegate> delegate;
@end

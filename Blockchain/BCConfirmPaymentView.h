//
//  BCConfirmPaymentView.h
//  Blockchain
//
//  Created by Kevin Wu on 10/2/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol TransactionDescriptionDelegate
- (void)setupNoteForTransaction:(NSString *)note;
@end
@interface BCConfirmPaymentView : UIView

- (id)initWithWindow:(UIView *)window
                from:(NSString *)from
                  To:(NSString *)to
              amount:(uint64_t)amount
                 fee:(uint64_t)fee
               total:(uint64_t)total
         description:(NSString *)description
               surge:(BOOL)surgePresent;

@property (nonatomic) UIButton *reallyDoPaymentButton;
@property (weak, nonatomic) id <TransactionDescriptionDelegate> delegate;
@end

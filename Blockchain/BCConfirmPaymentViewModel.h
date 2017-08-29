//
//  BCConfirmPaymentViewModel.h
//  Blockchain
//
//  Created by kevinwu on 8/29/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>
@class ContactTransaction;

@interface BCConfirmPaymentViewModel : NSObject

- (id)initWithFrom:(NSString *)from
                  To:(NSString *)to
              amount:(uint64_t)amount
                 fee:(uint64_t)fee
               total:(uint64_t)total
  contactTransaction:(ContactTransaction *)contactTransaction
               surge:(BOOL)surgePresent;

- (id)initWithTo:(NSString *)to
       ethAmount:(NSString *)ethAmount
          ethFee:(NSString *)ethFee
        ethTotal:(NSString *)ethTotal
      fiatAmount:(NSString *)fiatAmount
         fiatFee:(NSString *)fiatFee
       fiatTotal:(NSString *)fiatTotal;

@property (nonatomic) NSString *from;
@property (nonatomic) NSString *to;
@property (nonatomic) NSString *fiatTotalAmountText;
@property (nonatomic) NSString *btcTotalAmountText;
@property (nonatomic) NSString *fiatAmountText;
@property (nonatomic) NSString *btcAmountText;
@property (nonatomic) NSString *btcWithFiatAmountText;
@property (nonatomic) NSString *btcWithFiatFeeText;
@property (nonatomic) NSString *noteText;
@property (nonatomic) NSString *buttonTitle;
@property (nonatomic) BOOL surgeIsOccurring;
@end

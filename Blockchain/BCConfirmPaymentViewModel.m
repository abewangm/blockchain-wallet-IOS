//
//  BCConfirmPaymentViewModel.m
//  Blockchain
//
//  Created by kevinwu on 8/29/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCConfirmPaymentViewModel.h"
#import "ContactTransaction.h"
#import "NSNumberFormatter+Currencies.h"

@interface BCConfirmPaymentViewModel ()
@end
@implementation BCConfirmPaymentViewModel

- (id)initWithFrom:(NSString *)from
                To:(NSString *)to
            amount:(uint64_t)amount
               fee:(uint64_t)fee
             total:(uint64_t)total
contactTransaction:(ContactTransaction *)contactTransaction
             surge:(BOOL)surgePresent
{
    self = [super init];
    
    if (self) {
        self.from = from;
        self.to = to;
        self.surgeIsOccurring = surgePresent;
        
        if (contactTransaction) {
            self.buttonTitle = [contactTransaction.role isEqualToString:TRANSACTION_ROLE_RPR_INITIATOR] ? BC_STRING_SEND : BC_STRING_PAY;
            self.noteText = contactTransaction.reason;
        } else {
            self.buttonTitle = BC_STRING_SEND;
        }
        
        self.fiatTotalAmountText = [NSNumberFormatter formatMoney:total localCurrency:YES];
        self.btcTotalAmountText = [NSNumberFormatter formatBTC:total];
        self.btcWithFiatAmountText = [self formatAmountInBTCAndFiat:amount];
        self.btcWithFiatFeeText = [self formatAmountInBTCAndFiat:fee];
    }
    return self;
}

- (id)initWithTo:(NSString *)to
       ethAmount:(NSString *)ethAmount
          ethFee:(NSString *)ethFee
        ethTotal:(NSString *)ethTotal
      fiatAmount:(NSString *)fiatAmount
         fiatFee:(NSString *)fiatFee
       fiatTotal:(NSString *)fiatTotal
{
    if (self == [super init]) {
        self.to = to;
        self.fiatTotalAmountText = fiatTotal;
        self.btcTotalAmountText = ethTotal;
        self.btcWithFiatFeeText = [NSString stringWithFormat:@"%@ (%@)", ethFee, fiatFee];
    }
    return self;
}

- (id)initWithFrom:(NSString *)from
                To:(NSString *)to
            bchAmount:(uint64_t)amount
               fee:(uint64_t)fee
             total:(uint64_t)total
             surge:(BOOL)surgePresent
{
    self = [super init];
    
    if (self) {
        self.from = from;
        self.to = to;
        self.surgeIsOccurring = surgePresent;
        
        self.fiatTotalAmountText = [NSNumberFormatter formatBchWithSymbol:total localCurrency:YES];
        self.btcTotalAmountText = [NSNumberFormatter formatBCH:total];
        self.btcWithFiatAmountText = [self formatAmountInBCHAndFiat:amount];
        self.btcWithFiatFeeText = [self formatAmountInBCHAndFiat:fee];
    }
    return self;
}

#pragma mark - Text Helpers

- (NSString *)formatAmountInBTCAndFiat:(uint64_t)amount
{
    return [NSString stringWithFormat:@"%@ (%@)", [NSNumberFormatter formatMoney:amount localCurrency:NO], [NSNumberFormatter formatMoney:amount localCurrency:YES]];
}

- (NSString *)formatAmountInBCHAndFiat:(uint64_t)amount
{
    return [NSString stringWithFormat:@"%@ (%@)", [NSNumberFormatter formatBchWithSymbol:amount localCurrency:NO], [NSNumberFormatter formatBchWithSymbol:amount localCurrency:YES]];
}

@end

//
//  KIFUITestActor+Login.h
//  Blockchain
//
//  Created by Kevin Wu on 4/14/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import <KIF/KIF.h>

@interface KIFUITestActor (Login)
- (void)createNewWallet;
- (void)goToSend;
- (void)typeInAddress;
- (void)send;
- (void)confirmSendAmountDecimalPeriod;
- (void)confirmSendAmountDecimalComma;
- (void)confirmSendAmountDecimalArabicComma;
- (void)confirmSendAmountDecimalArabicCommaAndText;
- (void)confirmSendAmountDecimalCommaArabicText;
- (void)confirmSendAmountDecimalPeriodArabicText;

- (void)goToReceive;
- (uint64_t)confirmReceiveAmount:(NSString *)randomAmount;
- (uint64_t)computeBitcoinValue:(NSString *)amount;
@end

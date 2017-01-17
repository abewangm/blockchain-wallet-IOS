//
//  ContactTransaction.m
//  Blockchain
//
//  Created by kevinwu on 1/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactTransaction.h"

@implementation ContactTransaction
- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _identifier = [dictionary objectForKey:DICTIONARY_KEY_ID];
        _state = [dictionary objectForKey:DICTIONARY_KEY_STATE];
        _intendedAmount = [[dictionary objectForKey:DICTIONARY_KEY_INTENDED_AMOUNT] longLongValue];
        _role = [dictionary objectForKey:DICTIONARY_KEY_ROLE];
        _address = [dictionary objectForKey:DICTIONARY_KEY_ADDRESS];
        
        if ([_state isEqualToString:TRANSACTION_STATE_WAITING_PAYMENT]) {
            if ([_role isEqualToString:TRANSACTION_ROLE_PR_INITIATOR] || [_role isEqualToString:TRANSACTION_ROLE_RPR_INITIATOR]) {
                _transactionState = ContactTransactionStateReceiveWaitingForPayment;
            } else if ([_role isEqualToString:TRANSACTION_ROLE_PR_RECEIVER] || [_role isEqualToString:TRANSACTION_ROLE_RPR_RECEIVER]) {
                _transactionState = ContactTransactionStateSendReadyToSend;
            }
        } else if ([_state isEqualToString:TRANSACTION_STATE_WAITING_ADDRESS]) {
            if ([_role isEqualToString:TRANSACTION_ROLE_RPR_INITIATOR]) {
                _transactionState = ContactTransactionStateSendWaitingForQR;
            } else if ([_role isEqualToString:TRANSACTION_ROLE_RPR_RECEIVER]) {
                _transactionState = ContactTransactionStateReceiveAcceptOrDenyPayment;
            }
        }
    }
    return self;
}

@end

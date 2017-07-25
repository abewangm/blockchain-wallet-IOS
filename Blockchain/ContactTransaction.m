//
//  ContactTransaction.m
//  Blockchain
//
//  Created by kevinwu on 1/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactTransaction.h"

@implementation ContactTransaction
- (id)initWithDictionary:(NSDictionary *)dictionary contactIdentifier:(NSString *)identifier
{
    if (self = [super init]) {
        _identifier = [dictionary objectForKey:DICTIONARY_KEY_ID];
        _state = [dictionary objectForKey:DICTIONARY_KEY_STATE];
        _intendedAmount = [[dictionary objectForKey:DICTIONARY_KEY_INTENDED_AMOUNT] longLongValue];
        _role = [dictionary objectForKey:DICTIONARY_KEY_ROLE];
        _address = [dictionary objectForKey:DICTIONARY_KEY_ADDRESS];
        _reason = [dictionary objectForKey:DICTIONARY_KEY_NOTE];
        _contactIdentifier = identifier;
        self.lastUpdated = [[dictionary objectForKey:DICTIONARY_KEY_LAST_UPDATED] longLongValue] / 1000;
        _initiatorSource = [dictionary objectForKey:DICTIONARY_KEY_INITIATOR_SOURCE];
        
        self.note = [dictionary objectForKey:DICTIONARY_KEY_NOTE];
        self.myHash = [dictionary objectForKey:DICTIONARY_KEY_TX_HASH];
        
        if ([_state isEqualToString:TRANSACTION_STATE_WAITING_PAYMENT]) {
            if ([_role isEqualToString:TRANSACTION_ROLE_PR_INITIATOR] || [_role isEqualToString:TRANSACTION_ROLE_RPR_RECEIVER]) {
                _transactionState = ContactTransactionStateReceiveWaitingForPayment;
            } else if ([_role isEqualToString:TRANSACTION_ROLE_PR_RECEIVER] || [_role isEqualToString:TRANSACTION_ROLE_RPR_INITIATOR]) {
                _transactionState = ContactTransactionStateSendReadyToSend;
            }
        } else if ([_state isEqualToString:TRANSACTION_STATE_WAITING_ADDRESS]) {
            if ([_role isEqualToString:TRANSACTION_ROLE_RPR_INITIATOR]) {
                _transactionState = ContactTransactionStateSendWaitingForQR;
            } else if ([_role isEqualToString:TRANSACTION_ROLE_RPR_RECEIVER]) {
                _transactionState = ContactTransactionStateReceiveAcceptOrDenyPayment;
            }
        } else if ([_state isEqualToString:TRANSACTION_STATE_PAYMENT_BROADCASTED]) {
            if ([_role isEqualToString:TRANSACTION_ROLE_RPR_INITIATOR] || [_role isEqualToString:TRANSACTION_ROLE_PR_RECEIVER]) {
                _transactionState = ContactTransactionStateCompletedSend;
            } else if ([_role isEqualToString:TRANSACTION_ROLE_PR_INITIATOR] || [_role isEqualToString:TRANSACTION_ROLE_RPR_RECEIVER]) {
                _transactionState = ContactTransactionStateCompletedReceive;
            }
        } else if ([_state isEqualToString:TRANSACTION_STATE_DECLINED]) {
            _transactionState = ContactTransactionStateDeclined;
        } else if ([_state isEqualToString:TRANSACTION_STATE_CANCELLED]) {
            _transactionState = ContactTransactionStateCancelled;
        }
    }
    return self;
}

+ (ContactTransaction *)transactionWithTransaction:(ContactTransaction *)contactTransaction existingTransaction:(Transaction *)existingTransaction
{
    contactTransaction.to = existingTransaction.to;
    contactTransaction.from = existingTransaction.from;
    contactTransaction.block_height = existingTransaction.block_height;
    contactTransaction.confirmations = existingTransaction.confirmations;
    contactTransaction.fee = existingTransaction.fee;
    contactTransaction.myHash = existingTransaction.myHash;
    contactTransaction.txType = existingTransaction.txType;
    contactTransaction.amount = existingTransaction.amount;
    contactTransaction.time = existingTransaction.time;
    contactTransaction.fromWatchOnly = existingTransaction.fromWatchOnly;
    contactTransaction.toWatchOnly = existingTransaction.toWatchOnly;
    contactTransaction.note = existingTransaction.note;
    contactTransaction.doubleSpend = existingTransaction.doubleSpend;
    contactTransaction.replaceByFee = existingTransaction.replaceByFee;
    
    contactTransaction.fiatAmountsAtTime = existingTransaction.fiatAmountsAtTime;
    
    return contactTransaction;
}

@end

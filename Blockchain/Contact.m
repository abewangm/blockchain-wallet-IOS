//
//  Contact.m
//  Blockchain
//
//  Created by Kevin Wu on 12/7/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "Contact.h"
#import "ContactTransaction.h"

@implementation Contact

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _company = [self getStringForKey:DICTIONARY_KEY_COMPANY fromDictionary:dictionary];
        _email = [self getStringForKey:DICTIONARY_KEY_EMAIL fromDictionary:dictionary];
        _identifier = [self getStringForKey:DICTIONARY_KEY_ID fromDictionary:dictionary];
        _invitationReceived = [self getStringForKey:DICTIONARY_KEY_INVITATION_RECEIVED fromDictionary:dictionary];
        _invitationSent = [self getStringForKey:DICTIONARY_KEY_INVITATION_SENT fromDictionary:dictionary];
        _mdid = [self getStringForKey:DICTIONARY_KEY_MDID fromDictionary:dictionary];
        _name = [self getStringForKey:DICTIONARY_KEY_NAME fromDictionary:dictionary];
        _note = [self getStringForKey:DICTIONARY_KEY_NOTE fromDictionary:dictionary];
        _pubKey = [self getStringForKey:DICTIONARY_KEY_PUBKEY fromDictionary:dictionary];
        _surname = [self getStringForKey:DICTIONARY_KEY_SURNAME fromDictionary:dictionary];
        _trusted = [[dictionary objectForKey:DICTIONARY_KEY_TRUSTED] boolValue];
        _xpub = [self getStringForKey:DICTIONARY_KEY_XPUB fromDictionary:dictionary];
        
        NSDictionary *transactionListDict = [dictionary objectForKey:DICTIONARY_KEY_TRANSACTION_LIST];
        NSArray *transactionListArray = [transactionListDict allValues];
        
        NSMutableDictionary *finalTransactionList = [NSMutableDictionary new];
        for (NSDictionary *facilitatedTransaction in transactionListArray) {
            ContactTransaction *transaction = [[ContactTransaction alloc] initWithDictionary:facilitatedTransaction contactIdentifier:_identifier];
            [finalTransactionList setObject:transaction forKey:transaction.identifier];
        }
        
        _transactionList = [[NSDictionary alloc] initWithDictionary:finalTransactionList];
    }
    return self;
}

- (NSString *)getStringForKey:(NSString *)key fromDictionary:(NSDictionary *)dictionary
{
    NSString *string = [dictionary objectForKey:key];
    // Check for null
    return [string isKindOfClass:[NSString class]] ? string : nil;
}

@end

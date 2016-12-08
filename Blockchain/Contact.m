//
//  Contact.m
//  Blockchain
//
//  Created by Kevin Wu on 12/7/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "Contact.h"

@implementation Contact

- (id)initWithDictionary:(NSDictionary *)dictionary
{
    if (self = [super init]) {
        _company = [dictionary objectForKey:DICTIONARY_KEY_COMPANY];
        _email = [dictionary objectForKey:DICTIONARY_KEY_EMAIL];
        _identifier = [dictionary objectForKey:DICTIONARY_KEY_ID];
        _invitationReceived = [dictionary objectForKey:DICTIONARY_KEY_INVITATION_RECEIVED];
        _invitationSent = [dictionary objectForKey:DICTIONARY_KEY_INVITATION_SENT];
        _mdid = [dictionary objectForKey:DICTIONARY_KEY_MDID];
        _name = [dictionary objectForKey:DICTIONARY_KEY_NAME];
        _note = [dictionary objectForKey:DICTIONARY_KEY_NOTE];
        _pubKey = [dictionary objectForKey:DICTIONARY_KEY_PUBKEY];
        _surname = [dictionary objectForKey:DICTIONARY_KEY_SURNAME];
        _trusted = [[dictionary objectForKey:DICTIONARY_KEY_TRUSTED] boolValue];
        _xpub = [dictionary objectForKey:DICTIONARY_KEY_XPUB];
    }
    return self;
}

@end

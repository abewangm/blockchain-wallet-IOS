//
//  Contact.h
//  Blockchain
//
//  Created by Kevin Wu on 12/7/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Contact : NSObject

@property (nonatomic, readonly) NSString *company;
@property (nonatomic, readonly) NSString *email;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *invitationReceived;
@property (nonatomic, readonly) NSString *invitationSent;
@property (nonatomic, readonly) NSString *mdid;
@property (nonatomic, readonly) NSString *name;
@property (nonatomic, readonly) NSString *note;
@property (nonatomic, readonly) NSString *pubKey;
@property (nonatomic, readonly) NSString *surname;
@property (nonatomic, readonly) BOOL trusted;
@property (nonatomic, readonly) NSString *xpub;

- (id)initWithDictionary:(NSDictionary *)dictionary;

@end

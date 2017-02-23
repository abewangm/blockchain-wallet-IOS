//
//  ContactsViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 11/1/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ContactsViewController : UIViewController

- (id)initWithInvitation:(NSString *)identifier name:(NSString *)name;
- (id)initWithAcceptedInvitation:(NSString *)invitationSent;
- (id)initWithMessageIdentifier:(NSString *)messageIdentifier;

- (void)showAcceptedInvitation:(NSString *)invitationSent;
- (void)showRequest:(NSString *)messageIdentifier;

- (void)didCreateInvitation:(NSDictionary *)invitationDict;
- (void)didReadInvitation:(NSDictionary *)invitation identifier:(NSString *)identifier;
- (void)didAcceptRelation:(NSString *)invitation name:(NSString *)name;
- (void)didCompleteRelation;

// Messages Controller
- (void)didGetMessages;
- (void)didChangeContactName;

// Detail Controller
- (void)didChangeTrust;
- (void)didFetchExtendedPublicKey;
- (NSString *)currentTransactionHash;
- (void)reloadSymbols;
@end

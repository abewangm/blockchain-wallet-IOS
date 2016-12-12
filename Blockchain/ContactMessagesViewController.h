//
//  ContactMessagesViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 12/8/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Contact;
@interface ContactMessagesViewController : UIViewController
@property (nonatomic) Contact *contact;
- (id)initWithContact:(Contact *)contact messages:(NSArray *)messages;

- (void)didFetchExtendedPublicKey;
- (void)didGetMessages;
- (void)didReadMessage:(NSString *)message;
@end

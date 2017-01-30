//
//  ContactDetailViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 12/7/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@class Contact;
@interface ContactDetailViewController : UIViewController
@property (nonatomic) Contact *contact;
- (id)initWithContact:(Contact *)contact;
- (id)initWithContact:(Contact *)contact selectMessage:(NSString *)messageIdentifier;

- (void)showExtendedPublicKey;
- (void)didGetMessages:(Contact *)contact;
- (void)didSendPaymentRequest;
- (void)didRequestPaymentRequest;

- (NSString *)getTransactionHash;
- (void)reloadSymbols;
@end

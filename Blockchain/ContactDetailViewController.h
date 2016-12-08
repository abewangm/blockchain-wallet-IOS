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
- (id)initWithContact:(Contact *)contact;
- (void)didChangeTrust:(BOOL)result;
@end

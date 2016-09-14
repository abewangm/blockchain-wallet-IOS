//
//  TransactionRecipientsViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 9/12/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
@protocol RecipientsDelegate
- (BOOL)isWatchOnlyLegacyAddress:(NSString *)addr;
@end
@interface TransactionRecipientsViewController : UIViewController
@property (nonatomic) id<RecipientsDelegate> delegate;
- (id)initWithRecipients:(NSArray *)recipients;
@end

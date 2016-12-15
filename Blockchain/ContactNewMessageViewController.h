//
//  ContactNewMessageViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 12/14/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol SendMessageDelegate
- (void)sendMessage:(NSString *)message;
@end

@interface ContactNewMessageViewController : UIViewController
@property (nonatomic) id <SendMessageDelegate> delegate;

- (id)initWithContactIdentifier:(NSString *)identifier;
@end

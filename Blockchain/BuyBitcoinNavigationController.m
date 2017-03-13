//
//  BuyBitcoinNavigationController.m
//  Blockchain
//
//  Created by kevinwu on 3/13/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BuyBitcoinNavigationController.h"

@interface BuyBitcoinNavigationController ()
@property (nonatomic) BOOL willAttemptDismissTwice;
@end

@implementation BuyBitcoinNavigationController

- (void)dismissViewControllerAnimated:(BOOL)flag completion:(void (^)(void))completion
{
    // http://stackoverflow.com/questions/35999551/uiimagepickercontroller-view-is-not-in-the-window-hierarchy
    
    BOOL willAttemptDismissTwice = [self.presentedViewController isMemberOfClass:[UIImagePickerController class]];
    
    if (!self.willAttemptDismissTwice) {
        [super dismissViewControllerAnimated:flag completion:completion];
    }
    
    self.willAttemptDismissTwice = willAttemptDismissTwice;
}

@end

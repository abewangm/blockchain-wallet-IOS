//
//  UIAlertController+AutoDismiss.m
//  Blockchain
//
//  Created by Kevin Wu on 9/30/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//

#import "UIAlertController+AutoDismiss.h"

@implementation UIAlertController (AutoDismiss)

- (void)autoDismiss
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

//
//  BCRecoveryView.m
//  Blockchain
//
//  Created by Matt Tuzzolo on 10/2/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//

#import "BCRecoveryView.h"

@implementation BCRecoveryView

- (void)modalWasDismissed{
    
    self.recoveryPassphraseTextField.text = @"";
}

@end

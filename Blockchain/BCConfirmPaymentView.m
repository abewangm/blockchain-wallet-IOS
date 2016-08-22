//
//  BCConfirmPaymentView.m
//  Blockchain
//
//  Created by Kevin Wu on 10/2/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCConfirmPaymentView.h"

@implementation BCConfirmPaymentView

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.arrowImageView.image = [self.arrowImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    [self.arrowImageView setTintColor:COLOR_BLOCKCHAIN_BLUE];
}

@end

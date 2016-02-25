//
//  BCInsetLabel.m
//  Blockchain
//
//  Created by Kevin Wu on 2/25/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import "BCInsetLabel.h"

@implementation BCInsetLabel

- (void)drawTextInRect:(CGRect)rect
{
    [super drawTextInRect:UIEdgeInsetsInsetRect(rect, self.customEdgeInsets)];
}

@end

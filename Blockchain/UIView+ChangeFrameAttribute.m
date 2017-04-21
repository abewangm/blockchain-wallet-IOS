//
//  UIView+ChangeFrameAttribute.m
//  Blockchain
//
//  Created by kevinwu on 4/20/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "UIView+ChangeFrameAttribute.h"

@implementation UIView (ChangeFrameAttribute)

- (void)increaseXPosition:(CGFloat)XOffset
{
    self.frame = CGRectOffset(self.frame, XOffset, 0);
}

- (void)changeXPosition:(CGFloat)newX
{
    self.frame = CGRectMake(newX, self.frame.origin.y, self.frame.size.width, self.frame.size.height);
}

- (void)changeYPosition:(CGFloat)newY
{
    self.frame = CGRectMake(self.frame.origin.x, newY, self.frame.size.width, self.frame.size.height);
}

- (void)changeWidth:(CGFloat)newWidth
{
    self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, newWidth, self.frame.size.height);
}

- (void)centerXToSuperView
{
    self.center = CGPointMake(self.superview.center.x, self.center.y);
}

@end

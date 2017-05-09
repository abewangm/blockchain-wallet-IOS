//
//  UIView+ChangeFrameAttribute.h
//  Blockchain
//
//  Created by kevinwu on 4/20/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ChangeFrameAttribute)
- (void)increaseXPosition:(CGFloat)XOffset;
- (void)changeXPosition:(CGFloat)newX;
- (void)changeYPosition:(CGFloat)newY;
- (void)changeWidth:(CGFloat)newWidth;
- (void)changeHeight:(CGFloat)newHeight;
- (void)centerXToSuperView;
@end

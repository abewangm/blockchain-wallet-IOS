//
//  UIView+ChangeFrameAttribute.h
//  Blockchain
//
//  Created by kevinwu on 4/20/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIView (ChangeFrameAttribute)
- (void)increaseXPosition:(CGFloat)newX;
- (void)changeYPosition:(CGFloat)newY;
- (void)changeWidth:(CGFloat)newWidth;
- (void)centerXToSuperView;
@end

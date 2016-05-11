//
//  UIFadeView.m
//  Blockchain
//
//  Created by Ben Reeves on 16/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "BCFadeView.h"

typedef enum {
    backgroundDark = 100,
    backgroundTransparent = 200,
}BackgroundType;

@implementation BCFadeView

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setup];
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.defaultBackgroundColor = self.backgroundColor;
}

- (void)fadeInWithTransparentBackground
{
    [self fadeInWithBackground:backgroundTransparent];
}

- (void)fadeInWithDarkBackground
{
    [self fadeInWithBackground:backgroundDark];
}

- (void)fadeInWithBackground:(BackgroundType)backgroundType
{
    self.containerView.layer.cornerRadius = 5;
    
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDelegate:self];
    self.alpha = 1.0;
    [UIView commitAnimations];
    
    if (backgroundType == backgroundTransparent) {
        self.backgroundColor = [UIColor clearColor];
    } else if (backgroundType == backgroundDark) {
        self.backgroundColor = self.defaultBackgroundColor;
    }
}

- (void)fadeOut
{
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
    [UIView setAnimationDidStopSelector:@selector(removeModalView)];
    self.alpha = 0.0;
    [UIView commitAnimations];
}

- (void)removeModalView
{
    [self removeFromSuperview];
}

@end

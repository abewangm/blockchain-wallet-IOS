//
//  BCCardView.m
//  Blockchain
//
//  Created by kevinwu on 3/28/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCCardView.h"
@interface BCCardView ()
@end

@implementation BCCardView

- (id)initWithContainerFrame:(CGRect)frame title:(NSString *)title description:(NSString *)description actionName:(NSString *)actionName imageName:(NSString *)imageName delegate:(id<CardViewDelegate>)delegate
{
    if (self == [super init]) {
        
        self.frame = CGRectInset(frame, 8, 16);
        
        self.layer.masksToBounds = NO;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 2;
        self.layer.shadowOpacity = 0.15;
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        
        self.backgroundColor = [UIColor whiteColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 16, 90, 110)];
        imageView.image = [UIImage imageNamed:imageName];
        [self addSubview:imageView];
        
        CGFloat textWidth = self.frame.size.width - imageView.frame.size.width - 8;
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.size.width + 8, imageView.frame.origin.y, textWidth, 54)];
        titleLabel.numberOfLines = 0;
        titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:14];
        titleLabel.text = title;
        titleLabel.backgroundColor = [UIColor clearColor];
        [titleLabel sizeToFit];
        [self addSubview:titleLabel];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x, titleLabel.frame.origin.y + titleLabel.frame.size.height, textWidth, imageView.frame.size.height - titleLabel.frame.size.height)];
        descriptionLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:14];
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.adjustsFontSizeToFitWidth = YES;
        descriptionLabel.text = description;
        descriptionLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:descriptionLabel];
    }
    return self;
}

@end

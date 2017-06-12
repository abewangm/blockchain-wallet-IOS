//
//  BCCardView.m
//  Blockchain
//
//  Created by kevinwu on 3/28/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCCardView.h"
@interface BCCardView ()
@property (nonatomic) ActionType actionType;
@property (nonatomic) BOOL reducedHeightForPageIndicator;
@end

@implementation BCCardView

- (id)initWithContainerFrame:(CGRect)frame title:(NSString *)title description:(NSString *)description actionType:(ActionType)actionType imageName:(NSString *)imageName reducedHeightForPageIndicator:(BOOL)reducedHeightForPageIndicator delegate:(id<CardViewDelegate>)delegate
{
    if (self == [super init]) {
        
        self.delegate = delegate;
        self.actionType = actionType;
        self.reducedHeightForPageIndicator = reducedHeightForPageIndicator;
        
        self.frame = [self frameFromContainer:frame];
        
        self.layer.masksToBounds = NO;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 2;
        self.layer.shadowOpacity = 0.15;
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        
        self.backgroundColor = [UIColor whiteColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 16, 100, 100)];
        imageView.image = [UIImage imageNamed:imageName];
        [self addSubview:imageView];
        
        CGFloat textWidth = self.frame.size.width - imageView.frame.size.width - 16;
        
        NSString *actionName;
        UIColor *actionColor;
        UIColor *titleColor;

        if (actionType == ActionTypeScanQR) {
            actionName = BC_STRING_SCAN_ADDRESS;
            actionColor = COLOR_BLOCKCHAIN_BLUE;
            titleColor = actionColor;
        } else if (actionType == ActionTypeShowReceive) {
            actionName = BC_STRING_RECEIVE;
            actionColor = COLOR_BLOCKCHAIN_AQUA;
            titleColor = actionColor;
        } else if (actionType == ActionTypeBuyBitcoin) {
            actionName = BC_STRING_BUY_BITCOIN;
            actionColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
            titleColor = actionColor;
        } else if (actionType == ActionTypeBuyBitcoinAvailableNow) {
            actionName = BC_STRING_BUY_BITCOIN;
            actionColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
            titleColor = COLOR_BLOCKCHAIN_BLUE;
        }
        
        UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(imageView.frame.size.width + 8, imageView.frame.origin.y, textWidth, 54)];
        titleLabel.numberOfLines = 0;
        titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL_MEDIUM];
        titleLabel.text = title;
        titleLabel.textColor = titleColor;
        titleLabel.backgroundColor = [UIColor clearColor];
        [titleLabel sizeToFit];
        [self addSubview:titleLabel];
        
        UILabel *descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(titleLabel.frame.origin.x, titleLabel.frame.origin.y + titleLabel.frame.size.height, textWidth, imageView.frame.size.height - titleLabel.frame.size.height)];
        descriptionLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
        descriptionLabel.numberOfLines = 0;
        descriptionLabel.adjustsFontSizeToFitWidth = YES;
        descriptionLabel.text = description;
        descriptionLabel.textColor = COLOR_TEXT_DARK_GRAY;
        descriptionLabel.backgroundColor = [UIColor clearColor];
        [self addSubview:descriptionLabel];
        
        CGFloat buttonYOrigin = descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height;
        
        UIButton *actionButton = [[UIButton alloc] initWithFrame:CGRectMake(descriptionLabel.frame.origin.x, buttonYOrigin, textWidth, self.frame.size.height - buttonYOrigin)];
        actionButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL_MEDIUM];
        actionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [actionButton setTitleColor:actionColor forState:UIControlStateNormal];
        [actionButton setTitle:actionName forState:UIControlStateNormal];
        UIImage *chevronImage = [UIImage imageNamed:@"chevron_right"];
        [actionButton setImage:[chevronImage imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        actionButton.tintColor = actionColor;
        
        [actionButton sizeToFit];
        actionButton.frame = CGRectInset(actionButton.frame, -8, -10);
        actionButton.frame = CGRectMake(descriptionLabel.frame.origin.x, descriptionLabel.frame.origin.y, actionButton.frame.size.width, actionButton.frame.size.height);
        actionButton.center = CGPointMake(actionButton.center.x, buttonYOrigin + (self.frame.size.height - buttonYOrigin)/2);
        
        actionButton.titleEdgeInsets = UIEdgeInsetsMake(0, -actionButton.imageView.frame.size.width, 0, actionButton.imageView.frame.size.width);
        actionButton.imageEdgeInsets = UIEdgeInsetsMake(16, actionButton.titleLabel.frame.size.width + 4, 14, -actionButton.titleLabel.frame.size.width);
        actionButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        
        [actionButton addTarget:self action:@selector(actionButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:actionButton];
    }
    return self;
}

- (CGRect)frameFromContainer:(CGRect)containerFrame
{
    CGRect frame = CGRectInset(containerFrame, 8, 16);
    return CGRectMake(frame.origin.x, frame.origin.y, frame.size.width, self.reducedHeightForPageIndicator ? frame.size.height - 32 : frame.size.height);
}

- (void)actionButtonClicked
{
    [self.delegate cardActionClicked:self.actionType];
}

@end

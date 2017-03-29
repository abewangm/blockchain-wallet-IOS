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
@end

@implementation BCCardView

- (id)initWithContainerFrame:(CGRect)frame title:(NSString *)title description:(NSString *)description actionType:(ActionType)actionType imageName:(NSString *)imageName delegate:(id<CardViewDelegate>)delegate
{
    if (self == [super init]) {
        
        self.delegate = delegate;
        self.actionType = actionType;
        
        self.frame = CGRectInset(frame, 8, 16);
        self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, self.frame.size.width, self.frame.size.height - 32);
        
        self.layer.masksToBounds = NO;
        self.layer.shadowOffset = CGSizeMake(0, 2);
        self.layer.shadowRadius = 2;
        self.layer.shadowOpacity = 0.15;
        self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
        
        self.backgroundColor = [UIColor whiteColor];
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 16, 100, 100)];
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
        
        CGFloat buttonYOrigin = descriptionLabel.frame.origin.y + descriptionLabel.frame.size.height;
        
        NSString *actionName;
        
        if (actionType == ActionTypeScanQR) {
            actionName = BC_STRING_SCAN_ADDRESS;
        } else if (actionType == ActionTypeShowReceive) {
            actionName = BC_STRING_OVERVIEW_RECEIVE_BITCOIN_TITLE;
        } else if (actionType == ActionTypeBuyBitcoin) {
            actionName = BC_STRING_BUY_BITCOIN;
        }
        
        UIButton *actionButton = [[UIButton alloc] initWithFrame:CGRectMake(descriptionLabel.frame.origin.x, buttonYOrigin, textWidth, self.frame.size.height - buttonYOrigin)];
        actionButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:14];
        actionButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        [actionButton setTitleColor:COLOR_BLOCKCHAIN_BLUE forState:UIControlStateNormal];
        [actionButton setTitle:actionName forState:UIControlStateNormal];
        [actionButton addTarget:self action:@selector(actionButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self addSubview:actionButton];
    }
    return self;
}

- (void)actionButtonClicked
{
    [self.delegate actionClicked:self.actionType];
}

@end

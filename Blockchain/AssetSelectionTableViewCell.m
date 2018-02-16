//
//  AssetSelectionTableViewCell.m
//  Blockchain
//
//  Created by kevinwu on 2/14/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "AssetSelectionTableViewCell.h"
#import "UIView+ChangeFrameAttribute.h"

@interface AssetSelectionTableViewCell ()
@property (nonatomic) UIView *containerView;
@property (nonatomic) UILabel *label;
@property (nonatomic) UIImageView *assetImageView;
@property (nonatomic) UIImageView *downwardChevron;
@end

@implementation AssetSelectionTableViewCell

- (id)initWithAsset:(AssetType)assetType
{
    if (self == [super init]) {
        
        self.backgroundColor = [UIColor clearColor];
        
        CGFloat imageViewHeight = 26;
        NSString *text;
        
        if (assetType == AssetTypeBitcoin) {
            text = BC_STRING_BITCOIN;
        } else if (assetType == AssetTypeEther) {
            text = BC_STRING_ETHER;
        } else if (assetType == AssetTypeBitcoinCash) {
            text = BC_STRING_BITCOIN_CASH;
        }
        
        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
        self.label.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
        self.label.textColor = [UIColor whiteColor];
        self.label.text = text;
        [self.label sizeToFit];
        
        self.assetImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageViewHeight, imageViewHeight)];
        self.assetImageView.image = [UIImage imageNamed:@"bitcoin"];
        
        self.downwardChevron = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, imageViewHeight, imageViewHeight)];
        self.downwardChevron.image = [UIImage imageNamed:@"chevron_right"];
        
        self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.assetImageView.bounds.size.width + self.label.bounds.size.width + self.downwardChevron.bounds.size.width, imageViewHeight)];
        [self.containerView addSubview:self.label];
        [self.containerView addSubview:self.assetImageView];
        [self.containerView addSubview:self.downwardChevron];

        [self.assetImageView changeXPosition:0];
        [self.label changeXPosition:self.assetImageView.bounds.size.width];
        [self.downwardChevron changeXPosition:self.label.frame.origin.x + self.label.frame.size.width];
        [self addSubview:self.containerView];
    }
    
    return self;
}

- (void)layoutSubviews
{
    self.containerView.center = CGPointMake(self.frame.size.width/2, self.frame.size.height/2);
}

@end

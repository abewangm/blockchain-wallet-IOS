//
//  AssetSelectionTableViewCell.m
//  Blockchain
//
//  Created by kevinwu on 2/14/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "AssetSelectionTableViewCell.h"
#import "Assets.h"
#import "UIView+ChangeFrameAttribute.h"

@interface AssetSelectionTableViewCell ()
@property (nonatomic) UIView *containerView;
@property (nonatomic) UILabel *label;
@property (nonatomic) UIImageView *assetImageView;
@end

@implementation AssetSelectionTableViewCell

- (id)initWithAsset:(AssetType)assetType
{
    if (self == [super init]) {
        
        CGFloat height = 50;
        NSString *imageName;
        NSString *text;
        
        if (assetType == AssetTypeBitcoin) {
            text = BC_STRING_BITCOIN;
        } else if (assetType == AssetTypeEther) {
            text = BC_STRING_ETHER;
        } else if (assetType == AssetTypeBitcoinCash) {
            text = BC_STRING_BITCOIN_CASH;
        }
        
        self.label = [[UILabel alloc] initWithFrame:CGRectZero];
        self.label.text = text;
        [self.label sizeToFit];
        [self.containerView addSubview:self.label];
        
        self.assetImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, height, height)];
        self.assetImageView.image = [UIImage imageNamed:imageName];
        [self.containerView addSubview:self.assetImageView];
        
        self.containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.label.bounds.size.width + self.assetImageView.bounds.size.height, height)];
        [self.assetImageView changeXPosition:0];
        [self.label changeXPosition:self.assetImageView.bounds.size.width];
        [self addSubview:self.containerView];
    }
    
    return self;
}

@end

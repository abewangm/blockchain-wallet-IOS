//
//  AssetSelectorView.h
//  Blockchain
//
//  Created by kevinwu on 2/14/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Assets.h"

#define ASSET_SELECTOR_ROW_HEIGHT 36
@protocol AssetSelectorViewDelegate
- (void)didSelectAsset:(AssetType)assetType;
- (void)didOpenSelector;
@end
@interface AssetSelectorView : UIView
@property (nonatomic) AssetType selectedAsset;
@property (nonatomic, readonly) BOOL isOpen;
- (id)initWithFrame:(CGRect)frame delegate:(id<AssetSelectorViewDelegate>)delegate;
- (void)close;
- (void)open;

- (void)hide;
- (void)show;
@end

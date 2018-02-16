//
//  AssetSelectorView.h
//  Blockchain
//
//  Created by kevinwu on 2/14/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Assets.h"

@interface AssetSelectorView : UIView
@property (nonatomic) AssetType selectedAsset;
@property (nonatomic, readonly) BOOL isOpen;
- (id)initWithFrame:(CGRect)frame delegate:(id<UITableViewDelegate>)delegate;
- (void)selectorClicked;
- (void)close;
- (void)open;

- (void)hide;
- (void)show;
@end

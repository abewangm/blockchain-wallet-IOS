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
- (id)initWithFrame:(CGRect)frame delegate:(id<UITableViewDelegate>)delegate;
@end

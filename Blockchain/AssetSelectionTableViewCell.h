//
//  AssetSelectionTableViewCell.h
//  Blockchain
//
//  Created by kevinwu on 2/14/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Assets.h"

@interface AssetSelectionTableViewCell : UITableViewCell
@property (nonatomic, readonly) AssetType assetType;
- (id)initWithAsset:(AssetType)assetType;
@end

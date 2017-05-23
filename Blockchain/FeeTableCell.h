//
//  FeeTableCell.h
//  Blockchain
//
//  Created by kevinwu on 5/8/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FeeTypes.h"

@interface FeeTableCell : UITableViewCell
@property (nonatomic) UILabel *amountLabel;
@property (nonatomic) UILabel *nameLabel;
@property (nonatomic) UILabel *descriptionLabel;
@property (nonatomic, readonly) FeeType feeType;
@property (nonatomic, readonly) uint64_t amount;

- (id)initWithFeeType:(FeeType)feeType amount:(uint64_t)amount;

@end

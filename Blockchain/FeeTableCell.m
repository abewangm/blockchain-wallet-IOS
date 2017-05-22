//
//  FeeTableCell.m
//  Blockchain
//
//  Created by kevinwu on 5/8/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "FeeTableCell.h"

@implementation FeeTableCell

- (id)initWithFeeType:(FeeType)feeType
{
    if (self = [super init]) {
        _feeType = feeType;
        [self setup];
    }
    return self;
}

- (void)setup
{
    CGFloat leftLabelHeight = 22;
    
    self.nameLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.contentView.center.y - leftLabelHeight, 100, leftLabelHeight)];
    self.nameLabel.textColor = COLOR_TEXT_DARK_GRAY;
    self.nameLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL_MEDIUM];
    [self.contentView addSubview:self.nameLabel];

    self.descriptionLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, self.contentView.center.y, 200, leftLabelHeight)];
    self.descriptionLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL_MEDIUM];
    self.descriptionLabel.textColor = COLOR_LIGHT_GRAY;
    [self.contentView addSubview:self.descriptionLabel];

    if (self.feeType != FeeTypeCustom) {
        
        NSString *nameLabelText;
        NSString *descriptionLabelText;
        
        if (self.feeType == FeeTypeRegular) {
            nameLabelText = BC_STRING_REGULAR;
            descriptionLabelText = BC_STRING_GREATER_THAN_ONE_HOUR;
        } else if (self.feeType == FeeTypePriority) {
            nameLabelText = BC_STRING_PRIORITY;
            descriptionLabelText = BC_STRING_LESS_THAN_ONE_HOUR;
        }
        
        self.nameLabel.text = nameLabelText;
        self.descriptionLabel.text = descriptionLabelText;
        
        self.amountLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.frame.size.width - 100, 0, 100, 30)];
        self.amountLabel.text = BC_STRING_AMOUNT;
        self.amountLabel.textColor = COLOR_LABEL_BALANCE_GREEN;
        self.amountLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL_MEDIUM];
        self.amountLabel.center = CGPointMake(self.amountLabel.center.x, self.contentView.center.y);
        [self.contentView addSubview:self.amountLabel];
    } else {
        self.nameLabel.text = BC_STRING_CUSTOM;
        self.descriptionLabel.text = BC_STRING_ADVANCED_USERS_ONLY;
    }
}

@end

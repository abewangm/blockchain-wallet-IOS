//
//  TransactionDetailToCell.m
//  Blockchain
//
//  Created by Kevin Wu on 9/27/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailToCell.h"

@implementation TransactionDetailToCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.mainLabel setText:nil];
    [self.accessoryLabel setText:nil];
}

- (void)configureWithTransaction:(Transaction *)transaction
{
    [super configureWithTransaction:transaction];

    if (self.isSetup) {
        if (transaction.to.count > 1) {
            self.detailTextLabel.text = [NSString stringWithFormat:BC_STRING_ARGUMENT_RECIPIENTS, transaction.to.count];
        } else {
            self.accessoryLabel.text = [transaction.to.firstObject objectForKey:DICTIONARY_KEY_LABEL];
        }
        self.mainLabel.text = BC_STRING_TO;
        return;
    }
    
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, 0, 70, self.frame.size.height)];
    self.mainLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:self.mainLabel.font.pointSize];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.text = BC_STRING_TO;
    self.mainLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [self.contentView addSubview:self.mainLabel];
    
    if (transaction.to.count > 1) {
        self.detailTextLabel.text = [NSString stringWithFormat:BC_STRING_ARGUMENT_RECIPIENTS, transaction.to.count];
        self.detailTextLabel.textColor = COLOR_TEXT_DARK_GRAY;
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        CGFloat accessoryLabelXPosition = self.mainLabel.frame.origin.x + self.mainLabel.frame.size.width + 8;
        self.accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(accessoryLabelXPosition, 0, self.frame.size.width - self.contentView.layoutMargins.right - accessoryLabelXPosition, self.frame.size.height)];
        self.accessoryLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:self.accessoryLabel.font.pointSize];
        self.accessoryLabel.textAlignment = NSTextAlignmentRight;
        self.accessoryLabel.text = [transaction.to.firstObject objectForKey:DICTIONARY_KEY_LABEL];
        self.accessoryLabel.adjustsFontSizeToFitWidth = YES;
        self.accessoryLabel.textColor = COLOR_TEXT_DARK_GRAY;
        [self.contentView addSubview:self.accessoryLabel];
        self.accessoryType = UITableViewCellAccessoryNone;
    }
    
    self.isSetup = YES;
}

@end

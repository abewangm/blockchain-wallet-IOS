//
//  TransactionDetailToCell.m
//  Blockchain
//
//  Created by Kevin Wu on 9/27/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailToCell.h"
#import "ContactTransaction.h"

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
    
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    self.mainLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_MEDIUM_LARGE];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.text = BC_STRING_TO;
    self.mainLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [self.mainLabel sizeToFit];
    self.mainLabel.frame = CGRectMake(self.contentView.layoutMargins.left, 0, 70, 24);
    self.mainLabel.center = CGPointMake(self.mainLabel.center.x, self.contentView.center.y);
    [self.contentView addSubview:self.mainLabel];
    
    self.subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.mainLabel.frame.origin.y + self.mainLabel.frame.size.height, self.mainLabel.frame.size.width, 15)];
    self.subtitleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:12];
    self.subtitleLabel.adjustsFontSizeToFitWidth = YES;
    
    self.subtitleLabel.text = [transaction.txType isEqualToString:TX_TYPE_SENT] && [transaction isMemberOfClass:[ContactTransaction class]] ? [(ContactTransaction *)transaction contactName] : nil;
    self.subtitleLabel.textColor = COLOR_LIGHT_GRAY;
    [self.contentView addSubview:self.subtitleLabel];
    
    if (transaction.to.count > 1) {
        self.detailTextLabel.text = [NSString stringWithFormat:BC_STRING_ARGUMENT_RECIPIENTS, transaction.to.count];
        self.detailTextLabel.textColor = COLOR_TEXT_DARK_GRAY;
        self.detailTextLabel.adjustsFontSizeToFitWidth = YES;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    } else {
        CGFloat accessoryLabelXPosition = self.mainLabel.frame.origin.x + self.mainLabel.frame.size.width + 8;
        self.accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(accessoryLabelXPosition, 0, self.frame.size.width - self.contentView.layoutMargins.right - accessoryLabelXPosition, self.mainLabel.frame.size.height)];
        self.accessoryLabel.center = CGPointMake(self.accessoryLabel.center.x, self.contentView.center.y);
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

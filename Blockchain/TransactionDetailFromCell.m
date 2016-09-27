//
//  TransactionDetailFromCell.m
//  Blockchain
//
//  Created by Kevin Wu on 9/27/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailFromCell.h"

@implementation TransactionDetailFromCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    [self.mainLabel setText:nil];
    [self.accessoryLabel setText:nil];
    [self.accessoryButton setHidden:YES];
}

- (void)configureWithTransaction:(Transaction *)transaction
{
    [super configureWithTransaction:transaction];

    if (self.isSetup) {
        self.mainLabel.text = BC_STRING_FROM;
        self.accessoryLabel.text = transaction.from.label;
        return;
    }
    
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, 0, 70, 20.5)];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.text = BC_STRING_FROM;
    self.mainLabel.textColor = [UIColor lightGrayColor];
    [self.contentView addSubview:self.mainLabel];
    
    CGFloat accessoryLabelXPosition = self.mainLabel.frame.origin.x + self.mainLabel.frame.size.width + 8;
    self.accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(accessoryLabelXPosition, 0, self.frame.size.width - self.contentView.layoutMargins.right - accessoryLabelXPosition, 20.5)];
    self.accessoryLabel.textAlignment = NSTextAlignmentRight;
    self.accessoryLabel.adjustsFontSizeToFitWidth = YES;
    self.accessoryLabel.text = transaction.from.label;
    [self.contentView addSubview:self.accessoryLabel];
    
    self.isSetup = YES;
}

@end

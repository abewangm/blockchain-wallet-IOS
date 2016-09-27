//
//  TransactionDetailStatusCell.m
//  Blockchain
//
//  Created by Kevin Wu on 9/27/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailStatusCell.h"

@implementation TransactionDetailStatusCell

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
        self.mainLabel.text = BC_STRING_STATUS;
        self.accessoryButton.hidden = NO;
        return;
    }
    
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, 0, 70, self.frame.size.height)];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.text = BC_STRING_STATUS;
    self.mainLabel.textColor = [UIColor lightGrayColor];
    [self.contentView addSubview:self.mainLabel];
    
    CGFloat accessoryButtonXPosition = self.mainLabel.frame.origin.x + self.mainLabel.frame.size.width + 8;
    self.accessoryButton = [[UIButton alloc] initWithFrame:CGRectMake(accessoryButtonXPosition, 0, self.frame.size.width - self.contentView.layoutMargins.right - accessoryButtonXPosition, self.frame.size.height)];
    NSString *buttonTitle = transaction.confirmations >= kConfirmationThreshold ? BC_STRING_CONFIRMED : [NSString stringWithFormat:BC_STRING_PENDING_ARGUMENT_CONFIRMATIONS, [NSString stringWithFormat:@"%u/%u", transaction.confirmations, kConfirmationThreshold]];
    
    self.accessoryButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [self.accessoryButton addTarget:self action:@selector(showWebviewDetail) forControlEvents:UIControlEventTouchUpInside];
    [self.accessoryButton setTitle:buttonTitle forState:UIControlStateNormal];
    self.accessoryButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [self.accessoryButton setTitleColor:COLOR_BUTTON_BLUE forState:UIControlStateNormal];
    [self.contentView addSubview:self.accessoryButton];
    
    self.isSetup = YES;
}

- (void)showWebviewDetail
{
    [self.statusDelegate showWebviewDetail];
}

@end

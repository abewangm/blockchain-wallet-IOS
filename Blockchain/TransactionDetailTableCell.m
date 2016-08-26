//
//  TransactionDetailTableCell.m
//  Blockchain
//
//  Created by Kevin Wu on 8/24/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailTableCell.h"

@implementation TransactionDetailTableCell

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.textLabel.text = nil;
    [self.textView removeFromSuperview];
    [self.topLabel removeFromSuperview];
    [self.bottomLabel removeFromSuperview];
}

- (void)addTextView
{
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(self.frame.size.width/2, 0, self.frame.size.width/2, self.frame.size.height)];
    self.textView.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.textView];
}

- (void)addToAndFromLabels
{
    self.topLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.frame.size.height/2 - 30 - 4, 70, 30)];
    self.topLabel.text = BC_STRING_TO;
    self.bottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, self.frame.size.height/2 + 4, 70, 30)];
    self.bottomLabel.text = BC_STRING_FROM;
    [self addSubview:self.topLabel];
    [self addSubview:self.bottomLabel];
}

@end

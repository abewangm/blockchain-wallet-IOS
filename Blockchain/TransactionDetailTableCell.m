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
    [self.textView removeFromSuperview];
}

@end

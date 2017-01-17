//
//  ContactTransactionTableViewCell.h
//  Blockchain
//
//  Created by kevinwu on 1/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactTransaction.h"

@interface ContactTransactionTableViewCell : UITableViewCell
@property (nonatomic) ContactTransaction *transaction;
@property (nonatomic) UIImageView *actionImageView;
@property (nonatomic) UILabel *mainLabel;

- (void)configureWithTransaction:(ContactTransaction *)transaction;
@end

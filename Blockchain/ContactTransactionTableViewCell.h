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

@property (strong, nonatomic) IBOutlet UIButton *amountButton;
@property (strong, nonatomic) IBOutlet UILabel *lastUpdatedLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *toFromLabel;
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UILabel *bottomRightLabel;
@property (strong, nonatomic) IBOutlet UIImageView *actionImageView;

- (void)configureWithTransaction:(ContactTransaction *)transaction contactName:(NSString *)name;
- (void)transactionClicked:(UIButton *)button indexPath:(NSIndexPath *)indexPath;
- (IBAction)amountButtonClicked:(UIButton *)sender;
@end

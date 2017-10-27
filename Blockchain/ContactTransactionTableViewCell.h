//
//  ContactTransactionTableViewCell.h
//  Blockchain
//
//  Created by kevinwu on 1/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ContactTransaction.h"
#import "Contact.h"
@protocol ContactTransactionCellDelegate
- (void)sendPayment:(ContactTransaction *)transaction toContact:(Contact *)contact;
- (void)acceptOrDeclinePayment:(ContactTransaction *)transaction forContact:(Contact *)contact;
- (void)promptDeclinePayment:(ContactTransaction *)transaction forContact:(Contact *)contact;
- (void)promptCancelPayment:(ContactTransaction *)transaction forContact:(Contact *)contact;
@end
@interface ContactTransactionTableViewCell : UITableViewCell
@property (nonatomic) ContactTransaction *transaction;

@property (strong, nonatomic) IBOutlet UIButton *amountButton;
@property (strong, nonatomic) IBOutlet UILabel *lastUpdatedLabel;
@property (strong, nonatomic) IBOutlet UILabel *statusLabel;
@property (strong, nonatomic) IBOutlet UILabel *toFromLabel;
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UILabel *bottomRightLabel;
@property (strong, nonatomic) IBOutlet UIImageView *actionImageView;
@property (weak, nonatomic) id delegate;

- (void)configureWithTransaction:(ContactTransaction *)transaction contactName:(NSString *)name;
- (void)transactionClicked:(UIButton *)button;
- (IBAction)amountButtonClicked:(UIButton *)sender;
@end

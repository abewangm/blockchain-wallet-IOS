//
//  ExchangeTableViewCell.m
//  Blockchain
//
//  Created by kevinwu on 11/13/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeTableViewCell.h"
#import "NSDateFormatter+TimeAgoString.h"

#define STATUS_COMPLETE @"complete"
#define STATUS_IN_PROGRESS @"inprogress"
#define STATUS_CANCELLED @"cancelled"
#define STATUS_FAILED @"failed"
#define STATUS_EXPIRED @"expired"

@implementation ExchangeTableViewCell

- (void)configureWithTrade:(ExchangeTrade *)trade
{
    NSString *status = trade.status;
    
    UIColor *statusColor;
    if ([status isEqualToString:STATUS_COMPLETE]) {
        statusColor = COLOR_BLOCKCHAIN_GREEN;
    } else if ([status isEqualToString:STATUS_IN_PROGRESS]) {
        statusColor = COLOR_BLOCKCHAIN_GRAY_BLUE;
    } else if ([status isEqualToString:STATUS_CANCELLED] ||
               [status isEqualToString:STATUS_FAILED] ||
               [status isEqualToString:STATUS_EXPIRED]) {
        statusColor = COLOR_BLOCKCHAIN_RED;
    }
    
    self.actionLabel.textColor = statusColor;
    self.actionLabel.text = [status uppercaseString];
    self.amountButton.backgroundColor = statusColor;
    [self.amountButton setTitle:trade.withdrawalAmount forState:UIControlStateNormal];
    self.dateLabel.text = [NSDateFormatter timeAgoStringFromDate:trade.date];
}

@end

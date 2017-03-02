//
//  TransactionDetailDateCell.m
//  Blockchain
//
//  Created by Kevin Wu on 9/27/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailDateCell.h"

@implementation TransactionDetailDateCell

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

    NSString *dateString = [self getDateFromTransaction:transaction];
    
    if (self.isSetup) {
        self.mainLabel.text = BC_STRING_DATE;
        self.accessoryLabel.text = dateString;
        return;
    }
    
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.contentView.layoutMargins.left, 0, 70, self.frame.size.height)];
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    self.mainLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:16];
    self.mainLabel.text = BC_STRING_DATE;
    self.mainLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [self.contentView addSubview:self.mainLabel];
    
    CGFloat accessoryLabelXPosition = self.mainLabel.frame.origin.x + self.mainLabel.frame.size.width + 8;
    self.accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(accessoryLabelXPosition, 0, self.frame.size.width - self.contentView.layoutMargins.right - accessoryLabelXPosition, self.frame.size.height)];
    self.accessoryLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:16];
    self.accessoryLabel.adjustsFontSizeToFitWidth = YES;
    self.accessoryLabel.textAlignment = NSTextAlignmentRight;
    self.accessoryLabel.text = dateString;
    self.accessoryLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [self.contentView addSubview:self.accessoryLabel];
    
    self.isSetup = YES;
}

- (NSString *)getDateFromTransaction:(Transaction *)transaction
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setAMSymbol:@"am"];
    [dateFormatter setPMSymbol:@"pm"];
    [dateFormatter setDateFormat:@"MMMM dd, yyyy @ h:mmaa"];
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:transaction.time];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

@end

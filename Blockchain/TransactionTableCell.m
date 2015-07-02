//
//  TransactionTableCell.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "TransactionTableCell.h"
#import "Transaction.h"
#import "AppDelegate.h"
#import "TransactionsViewController.h"

@implementation TransactionTableCell

@synthesize transaction;

- (void)reload
{
    if (transaction == NULL)
        return;
    
    if (transaction.time > 0)  {
        dateLabel.hidden = NO;
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:transaction.time];
        
        long long secondsAgo  = -round([date timeIntervalSinceNow]);
        
        if (secondsAgo == 1) { // 1 second
            dateLabel.text = NSLocalizedString(@"1 second ago", nil);
        } else if (secondsAgo < 60) { // 0 - 59 seconds
            dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lld seconds ago", nil), secondsAgo];
        } else if (secondsAgo / 60 == 1) { // 1 minute
            dateLabel.text = NSLocalizedString(@"1 minute ago", nil);
        } else if (secondsAgo < 60 * 60) {  // 1 to 59 minutes
            dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lld minutes ago", nil), secondsAgo / 60];
        } else if (secondsAgo / 60 / 60 == 1) { // 1 hour ago
            dateLabel.text = NSLocalizedString(@"1 hour ago", nil);
        } else if ([[NSCalendar currentCalendar] respondsToSelector:@selector(isDateInToday:)] && secondsAgo < 60 * 60 * 24 && [[NSCalendar currentCalendar] isDateInToday:date]) { // 1 to 23 hours ago, but only if today
            dateLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%lld hours ago", nil), secondsAgo / 60 / 60];
        } else if([[NSCalendar currentCalendar] respondsToSelector:@selector(isDateInYesterday:)] && [[NSCalendar currentCalendar] isDateInYesterday:date]) { // yesterday
            dateLabel.text = NSLocalizedString(@"Yesterday", nil);
        } else if([[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:date] year] == [[[NSCalendar currentCalendar] components:NSCalendarUnitYear fromDate:[NSDate date]] year]) { // month + day (this year)
            NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
            NSString *longFormatWithoutYear = [NSDateFormatter dateFormatFromTemplate:@"MMMM d" options:0 locale:[NSLocale currentLocale]];
            [dateFormatter setDateFormat:longFormatWithoutYear];
            
            dateLabel.text = [dateFormatter stringFromDate:date];
        } else { // month + year (last year or earlier)
            NSDateFormatter* dateFormatter = [[NSDateFormatter alloc] init];
            NSString *longFormatWithoutYear = [NSDateFormatter dateFormatFromTemplate:@"MMMM y" options:0 locale:[NSLocale currentLocale]];
            [dateFormatter setDateFormat:longFormatWithoutYear];
            
            dateLabel.text = [dateFormatter stringFromDate:date];
        }

    } else {
        dateLabel.hidden = YES;
    }
    
    btcButton.titleLabel.minimumScaleFactor =  0.75f;
    [btcButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    [btcButton setTitle:[app formatMoney:ABS(transaction.result)] forState:UIControlStateNormal];
    
    if(transaction.intraWallet) {
        [btcButton setBackgroundColor:COLOR_TRANSACTION_TRANSFERRED];
        actionLabel.text = NSLocalizedString(@"TRANSFERRED", nil);
        actionLabel.textColor = COLOR_TRANSACTION_TRANSFERRED;
    } else if (transaction.result >= 0) {
        [btcButton setBackgroundColor:COLOR_TRANSACTION_RECEIVED];
        actionLabel.text = NSLocalizedString(@"RECEIVED", nil);
        actionLabel.textColor = COLOR_TRANSACTION_RECEIVED;
    } else {
        [btcButton setBackgroundColor:COLOR_TRANSACTION_SPENT];
        actionLabel.text = NSLocalizedString(@"SPENT", nil);
        actionLabel.textColor = COLOR_TRANSACTION_SPENT;
    }
    
    if (transaction.confirmations >= kConfirmationThreshold) {
        pendingText.hidden = YES;
        pendingIcon.hidden = YES;
        btcButton.alpha = 1;
        actionLabel.alpha = 1;
    } else {
        pendingText.hidden = NO;
        pendingIcon.hidden = NO;
        btcButton.alpha = 0.5;
        actionLabel.alpha = 0.5;
    }
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    // Configure the view for the selected state
}

#pragma mark button interactions

- (IBAction)transactionClicked:(UIButton *)button
{
    [app pushWebViewController:[WebROOT stringByAppendingFormat:@"tx/%@", transaction.myHash] title:BC_STRING_TRANSACTION];
}

- (IBAction)btcbuttonclicked:(id)sender
{
    [app toggleSymbol];
}

@end

//
//  TransactionTableCell.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionTableCell.h"
#import "Transaction.h"
#import "RootService.h"
#import "TransactionsViewController.h"
#import "TransactionDetailViewController.h"

@implementation TransactionTableCell

@synthesize transaction;

- (void)reload
{
    if (transaction == NULL)
        return;
    
    if (transaction.time > 0)  {
        dateLabel.adjustsFontSizeToFitWidth = YES;
        dateLabel.hidden = NO;
        
        NSDate *date = [NSDate dateWithTimeIntervalSince1970:transaction.time];
        
        long long secondsAgo  = -round([date timeIntervalSinceNow]);
        
        if (secondsAgo <= 1) { // Just now
            dateLabel.text = NSLocalizedString(@"Just now", nil);
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
    
    [btcButton setTitle:[NSNumberFormatter formatMoney:ABS(transaction.amount)] forState:UIControlStateNormal];
    
    if([transaction.txType isEqualToString:TX_TYPE_TRANSFER]) {
        [btcButton setBackgroundColor:COLOR_TRANSACTION_TRANSFERRED];
        actionLabel.text = [BC_STRING_TRANSFERRED uppercaseString];
        actionLabel.textColor = COLOR_TRANSACTION_TRANSFERRED;
    } else if ([transaction.txType isEqualToString:TX_TYPE_RECEIVED]) {
        [btcButton setBackgroundColor:COLOR_TRANSACTION_RECEIVED];
        actionLabel.text = [BC_STRING_RECEIVED uppercaseString];
        actionLabel.textColor = COLOR_TRANSACTION_RECEIVED;
    } else {
        [btcButton setBackgroundColor:COLOR_TRANSACTION_SENT];
        actionLabel.text = [BC_STRING_SENT uppercaseString];
        actionLabel.textColor = COLOR_TRANSACTION_SENT;
    }
    
    watchOnlyLabel.adjustsFontSizeToFitWidth = YES;
    watchOnlyLabel.layer.cornerRadius = 5;
    watchOnlyLabel.clipsToBounds = YES;
    watchOnlyLabel.text = BC_STRING_WATCH_ONLY;
    watchOnlyLabel.customEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 4);
    
    if ((([transaction.txType isEqualToString:TX_TYPE_RECEIVED] || [transaction.txType isEqualToString:TX_TYPE_TRANSFER]) && transaction.toWatchOnly) || ([transaction.txType isEqualToString:TX_TYPE_SENT] && transaction.fromWatchOnly)) {
        watchOnlyLabel.hidden = NO;
        actionLabel.frame = CGRectMake(actionLabel.frame.origin.x, 20, 172, 21);
        dateLabel.frame = CGRectMake(dateLabel.frame.origin.x, 3, dateLabel.frame.size.width, dateLabel.frame.size.height);
        pendingText.frame = CGRectMake(pendingText.frame.origin.x, 5, pendingText.frame.size.width, pendingText.frame.size.height);
        pendingIcon.frame = CGRectMake(pendingIcon.frame.origin.x, 6, pendingIcon.frame.size.width, pendingIcon.frame.size.height);
    } else {
        watchOnlyLabel.hidden = YES;
        actionLabel.frame = CGRectMake(actionLabel.frame.origin.x, 29, 172, 21);
        dateLabel.frame = CGRectMake(dateLabel.frame.origin.x, 11, dateLabel.frame.size.width, dateLabel.frame.size.height);
        pendingText.frame = CGRectMake(pendingText.frame.origin.x, 13, pendingText.frame.size.width, pendingText.frame.size.height);
        pendingIcon.frame = CGRectMake(pendingIcon.frame.origin.x, 14, pendingIcon.frame.size.width, pendingIcon.frame.size.height);
    }
    
    if (transaction.confirmations >= kConfirmationThreshold) {
        pendingText.hidden = YES;
        pendingIcon.hidden = YES;
        btcButton.alpha = 1;
        actionLabel.alpha = 1;
        dateLabel.frame = CGRectMake(dateLabel.frame.origin.x, dateLabel.frame.origin.y, 172, dateLabel.frame.size.height);
    } else {
        pendingText.hidden = NO;
        pendingIcon.hidden = NO;
        btcButton.alpha = 0.5;
        actionLabel.alpha = 0.5;
        dateLabel.frame = CGRectMake(dateLabel.frame.origin.x, dateLabel.frame.origin.y, 90, dateLabel.frame.size.height);
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
    TransactionDetailViewController *detailViewController = [TransactionDetailViewController new];
    detailViewController.transaction = transaction;
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:detailViewController];
    
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, navigationController.view.frame.size.width, DEFAULT_HEADER_HEIGHT)];
    topBar.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [navigationController.view addSubview:topBar];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 17.5, navigationController.view.frame.size.width - 160, 40)];
    headerLabel.font = [UIFont systemFontOfSize:22.0];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    headerLabel.text = BC_STRING_TRANSACTION;
    [topBar addSubview:headerLabel];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(navigationController.view.frame.size.width - 80, 15, 80, 51);
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    backButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    [backButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor colorWithWhite:0.56 alpha:1.0] forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(dismissDetails) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:backButton];
    
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [app.tabViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)dismissDetails
{
    [app.tabViewController dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)btcbuttonclicked:(id)sender
{
    [app toggleSymbol];
}

@end

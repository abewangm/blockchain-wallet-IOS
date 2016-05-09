//
//  TransactionsViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "TransactionsViewController.h"
#import "Transaction.h"
#import "TransactionTableCell.h"
#import "MultiAddressResponse.h"
#import "AppDelegate.h"

@implementation TransactionsViewController

@synthesize data;
@synthesize latestBlock;

BOOL animateNextCell;

UIRefreshControl *refreshControl;
int lastNumberTransactions = INT_MAX;

- (NSInteger)tableView:(UITableView *)_tableView numberOfRowsInSection:(NSInteger)section
{
    return [data.transactions count];
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    Transaction * transaction = [data.transactions objectAtIndex:[indexPath row]];
        
    TransactionTableCell * cell = (TransactionTableCell*)[tableView dequeueReusableCellWithIdentifier:@"transaction"];
        
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"TransactionCell" owner:nil options:nil] objectAtIndex:0];
    }
        
    cell.transaction = transaction;
        
    [cell reload];
        
    // Selected cell color
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    [cell setSelectedBackgroundView:v];
        
    return cell;
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    TransactionTableCell *cell = (TransactionTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [cell transactionClicked:nil];
        
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)drawRect:(CGRect)rect
{
	//Setup
	CGContextRef context = UIGraphicsGetCurrentContext();	
	CGContextSetShouldAntialias(context, YES);
	
    CGContextSetFillColorWithColor(context, [UIColor lightGrayColor].CGColor);
    CGContextFillRect(context, CGRectMake(0, 0, 320, 15));
}

- (CGFloat)tableView:(UITableView *)_tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

- (UITableView*)tableView
{
    return tableView;
}

- (void)setText
{
    // Data not loaded yet
    if (!self.data) {
        [noTransactionsView removeFromSuperview];
        
        self.filterIndex = FILTER_INDEX_ALL;
        filterLabel.text = BC_STRING_TOTAL_BALANCE;
        [balanceBigButton setTitle:@"" forState:UIControlStateNormal];
        [balanceSmallButton setTitle:@"" forState:UIControlStateNormal];
    }
    // Data loaded, but no transactions yet
    else if (self.data.transactions.count == 0) {
        [tableView.tableHeaderView addSubview:noTransactionsView];
        
        // Balance
        [balanceBigButton setTitle:[app formatMoney:[self getBalance] localCurrency:app->symbolLocal] forState:UIControlStateNormal];
        [balanceSmallButton setTitle:[app formatMoney:[self getBalance] localCurrency:!app->symbolLocal] forState:UIControlStateNormal];
    }
    // Data loaded and we have a balance - display the balance and transactions
    else {
        [noTransactionsView removeFromSuperview];
        
        // Balance
        [balanceBigButton setTitle:[app formatMoney:[self getBalance] localCurrency:app->symbolLocal] forState:UIControlStateNormal];
        [balanceSmallButton setTitle:[app formatMoney:[self getBalance] localCurrency:!app->symbolLocal] forState:UIControlStateNormal];
    }
}

- (void)setLatestBlock:(LatestBlock *)_latestBlock
{
    latestBlock = _latestBlock;
    
    if (latestBlock) {
        // TODO This only works if the unconfirmed transaction is included in the latest block, otherwise we would have to fetch history again to get the actual value
        // Update block index for new transactions
        for (int i = 0; i < self.data.transactions.count; i++) {
            if (((Transaction *) self.data.transactions[i]).block_height == 0) {
                ((Transaction *) self.data.transactions[i]).block_height = latestBlock.height;
            }
            else {
                break;
            }
        }
    }
}

- (void)animateNextCellAfterReload
{
    animateNextCell = YES;
}

- (void)reload
{
    [self setText];
    
    [tableView reloadData];
    
    [self reloadNewTransactions];
    
    [self animateFirstCell];
    
    [self reloadLastNumberOfTransactions];
}

- (void)reloadNewTransactions
{
    if (data.n_transactions > lastNumberTransactions) {
        uint32_t numNewTransactions = data.n_transactions - lastNumberTransactions;
        // Max number displayed
        if (numNewTransactions > data.transactions.count) {
            numNewTransactions = (uint32_t) data.transactions.count;
        }
        // We only do this for the last five transactions at most
        if (numNewTransactions > 5) {
            numNewTransactions = 5;
        }
        
        NSMutableArray *rows = [[NSMutableArray alloc] initWithCapacity:numNewTransactions];
        for (int i = 0; i < numNewTransactions; i++) {
            [rows addObject:[NSIndexPath indexPathForRow:i inSection:0]];
        }
        
        [tableView reloadRowsAtIndexPaths:rows withRowAnimation:UITableViewRowAnimationFade];
    }
}

- (void)animateFirstCell
{
    // Animate the first cell
    if (data.transactions.count > 0 && animateNextCell) {
        [tableView reloadRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:0 inSection:0]] withRowAnimation:UITableViewRowAnimationFade];
        animateNextCell = NO;
        
        // Without a delay, the notification will not get the new transaction, but the one before it
        [self performSelector:@selector(postReceivePaymentNotification) withObject:nil afterDelay:0.1f];
    }
}

- (void)reloadLastNumberOfTransactions
{
    // If all the data is available, set the lastNumberTransactions - reload gets called once when wallet is loaded and once when latest block is loaded
    if (app.latestResponse) {
        lastNumberTransactions = data.n_transactions;
    }
}

- (void)loadTransactions
{
    lastNumberTransactions = data.n_transactions;
    
    if (self.filterIndex == FILTER_INDEX_ALL) {
        [app.wallet getHistory];
    } else if (self.filterIndex == FILTER_INDEX_IMPORTED_ADDRESSES) {
        [app.wallet filterTransactionsByImportedAddresses];
    } else {
        [app.wallet filterTransactionsByAccount:self.filterIndex];
    }
    
    // This should be done when request has finished but there is no callback
    if (refreshControl && refreshControl.isRefreshing) {
        [refreshControl endRefreshing];
    }
}

- (NSDecimalNumber *)getAmountForReceivedTransaction:(Transaction *)transaction
{
    NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:ABS(transaction.amount)] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:SATOSHI]];
    DLog(@"TransactionsViewController: getting amount for received transaction");
    return number;
}

- (void)postReceivePaymentNotification
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_RECEIVE_PAYMENT object:nil userInfo:[NSDictionary dictionaryWithObject:[self getAmountForReceivedTransaction:[data.transactions firstObject]] forKey:DICTIONARY_KEY_AMOUNT]];
}

- (void)changeFilterLabel:(NSString *)newText
{
    filterLabel.text = newText;
}

- (void)hideFilterLabel
{
    filterLabel.hidden = YES;
}

- (void)showFilterLabel
{
    filterLabel.hidden = NO;
}

- (CGFloat)heightForFilterTableView
{
    CGFloat estimatedHeight = 44 * ([app.wallet getActiveAccountsCount] + 2);
    CGFloat largestAcceptableHeight = [[UIScreen mainScreen] bounds].size.height - 150;
    return estimatedHeight > largestAcceptableHeight ? largestAcceptableHeight : estimatedHeight;
}

- (uint64_t)getBalance
{
    if (self.filterIndex == FILTER_INDEX_ALL) {
        return [app.wallet getTotalActiveBalance];
    } else if (self.filterIndex == FILTER_INDEX_IMPORTED_ADDRESSES) {
        return [app.wallet getTotalBalanceForActiveLegacyAddresses];
    } else {
        return [app.wallet getBalanceForAccount:(int)self.filterIndex];
    }
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT);
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    
    [balanceBigButton.titleLabel setMinimumScaleFactor:.5f];
    [balanceBigButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    [balanceSmallButton.titleLabel setMinimumScaleFactor:.5f];
    [balanceSmallButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    [balanceBigButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
    [balanceSmallButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
    
    filterLabel.adjustsFontSizeToFitWidth = YES;
    
    [self setupBlueBackgroundForBounceArea];
    
    [self setupPullToRefresh];
    
    self.filterIndex = FILTER_INDEX_ALL;
    filterLabel.text = BC_STRING_TOTAL_BALANCE;
    
    [self reload];
}

- (void)setupBlueBackgroundForBounceArea
{
    // Blue background for bounce area
    CGRect frame = self.view.bounds;
    frame.origin.y = -frame.size.height;
    UIView* blueView = [[UIView alloc] initWithFrame:frame];
    blueView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.tableView addSubview:blueView];
    // Make sure the refresh control is in front of the blue area
    blueView.layer.zPosition -= 1;
}

- (void)setupPullToRefresh
{
    // Tricky way to get the refreshController to work on a UIViewController - @see http://stackoverflow.com/a/12502450/2076094
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    refreshControl = [[UIRefreshControl alloc] init];
    [refreshControl setTintColor:[UIColor whiteColor]];
    [refreshControl addTarget:self
                       action:@selector(loadTransactions)
             forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = refreshControl;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    app.mainTitleLabel.hidden = YES;
    app.mainTitleLabel.adjustsFontSizeToFitWidth = YES;
    
    if ([app.wallet didUpgradeToHd] && ([app.wallet hasLegacyAddresses] || [app.wallet getActiveAccountsCount] >= 2)) {
        [self showFilterLabel];
        app.mainLogoImageView.hidden = YES;
    } else {
        [self hideFilterLabel];
        app.mainLogoImageView.hidden = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    app.mainLogoImageView.hidden = YES;
    app.mainTitleLabel.hidden = NO;
    filterLabel.hidden = YES;
}

@end

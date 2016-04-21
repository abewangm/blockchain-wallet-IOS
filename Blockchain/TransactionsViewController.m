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
    if (_tableView == self.filterTableView) {
        return [app.wallet getActiveAccountsCount] + 2; // All + accounts + Imported Addresses
    } else {
        return [data.transactions count];
    }
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableView == self.filterTableView) {
        
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        
        if (indexPath.row == 0) {
            cell.textLabel.text = BC_STRING_ALL;
        } else if (indexPath.row == [self tableView:_tableView numberOfRowsInSection:0] - 1) {
            cell.textLabel.text = BC_STRING_IMPORTED_ADDRESSES;
        } else {
            cell.textLabel.text = [app.wallet getLabelForAccount:[app.wallet getIndexOfActiveAccount:(indexPath.row - 1)]];
        }
        
        return cell;
        
    } else {
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
}

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (_tableView == self.filterTableView) {
        
        if (indexPath.row == 0) {
            self.filterIndex = FILTER_INDEX_ALL;
            [self changeFilterButtonTitle:BC_STRING_ALL];
            [app.wallet removeTransactionsFilter];
        } else if (indexPath.row == [self tableView:_tableView numberOfRowsInSection:0] - 1) {
            self.filterIndex = FILTER_INDEX_IMPORTED_ADDRESSES;
            [self changeFilterButtonTitle:BC_STRING_IMPORTED_ADDRESSES];
            [app.wallet filterTransactionsByImportedAddresses];
        } else {
            self.filterIndex = [app.wallet getIndexOfActiveAccount:indexPath.row - 1];
            [self changeFilterButtonTitle:[app.wallet getLabelForAccount:self.filterIndex]];
            [app.wallet filterTransactionsByAccount:self.filterIndex];
        }
        
        [self toggleFilterMenu:nil];
        
    } else {
        TransactionTableCell *cell = (TransactionTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
        [cell transactionClicked:nil];
        
        [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
        [self closeFilterMenu];
    }
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
    if (_tableView == self.filterTableView) {
        return 44;
    } else {
        return 65;
    }
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
        [self changeFilterButtonTitle:BC_STRING_ALL];
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
    
    [app.wallet getHistory];
    
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

- (void)changeFilterButtonTitle:(NSString *)newTitle
{
    [filterTransactionsButton setTitle:newTitle forState:UIControlStateNormal];
    
    CGFloat spacing = 8;
    filterTransactionsButton.titleEdgeInsets = UIEdgeInsetsMake(0, -filterTransactionsButton.imageView.frame.size.width, 0, filterTransactionsButton.imageView.frame.size.width);
    filterTransactionsButton.imageEdgeInsets = UIEdgeInsetsMake(0, filterTransactionsButton.titleLabel.frame.size.width + spacing, 0, -filterTransactionsButton.titleLabel.frame.size.width);
}

- (void)toggleFilterMenu:(UIButton *)sender
{
    if (self.filterTableView) {
        [self closeFilterMenu];
    } else {
        self.filterTableView = [[UITableView alloc] initWithFrame:CGRectMake(sender.frame.origin.x, sender.frame.origin.y + sender.frame.size.height, sender.frame.size.width, [self heightForFilterTableView])];
        self.filterTableView.showsVerticalScrollIndicator = NO;
        self.filterTableView.dataSource = self;
        self.filterTableView.delegate = self;
        self.filterTableView.backgroundColor = [UIColor whiteColor];
        self.filterTableView.layer.masksToBounds = NO;
        self.filterTableView.layer.shadowRadius = 5;
        self.filterTableView.layer.shadowOpacity = 0.5;
        
        CATransition *transition = [CATransition animation];
        transition.duration = 0.25;
        transition.type = kCATransitionReveal;
        [self.filterTableView.layer addAnimation:transition forKey:nil];
        [app.window.rootViewController.view addSubview:self.filterTableView];
    }
}

- (void)closeFilterMenu
{
    [UIView animateWithDuration:0.2 animations:^{
        self.filterTableView.alpha = 0.0;
    } completion:^(BOOL finished) {
        [self.filterTableView removeFromSuperview];
        self.filterTableView = nil;
    }];
}

- (void)hideFilterButton
{
    filterTransactionsButton.hidden = YES;
}

- (void)showFilterButton
{
    filterTransactionsButton.hidden = NO;
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
        return [app.wallet getBalanceForAccount:self.filterIndex];
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
    
    [self setupBlueBackgroundForBounceArea];
    
    [self setupPullToRefresh];
    
    [filterTransactionsButton addTarget:self action:@selector(toggleFilterMenu:) forControlEvents:UIControlEventTouchUpInside];
    self.filterIndex = FILTER_INDEX_ALL;
    [self changeFilterButtonTitle:BC_STRING_ALL];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(closeFilterMenu)];
    [headerView addGestureRecognizer:tapGesture];
    
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
    
    if ([app.wallet didUpgradeToHd]) {
        [self showFilterButton];
        app.mainLogoImageView.hidden = YES;
    } else {
        [self hideFilterButton];
        app.mainLogoImageView.hidden = NO;
    }
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
    app.mainLogoImageView.hidden = YES;
    app.mainTitleLabel.hidden = NO;
    filterTransactionsButton.hidden = YES;
    if (self.filterTableView) {
        [self.filterTableView removeFromSuperview];
        self.filterTableView = nil;
    }
}

@end

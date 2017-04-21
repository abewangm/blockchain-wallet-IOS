//
//  TransactionsViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 10/01/2012.
//  Copyright (c) 2012 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionsViewController.h"
#import "Transaction.h"
#import "TransactionTableCell.h"
#import "MultiAddressResponse.h"
#import "RootService.h"
#import "TransactionDetailViewController.h"
#import "BCAddressSelectionView.h"
#import "TransactionDetailNavigationController.h"
#import "BCCardView.h"

@interface TransactionsViewController () <AddressSelectionDelegate, CardViewDelegate, UIScrollViewDelegate>

// Onboarding

@property (nonatomic) BOOL isUsingPageControl;
@property (nonatomic) UIPageControl *pageControl;
@property (nonatomic) UIButton *startOverButton;
@property (nonatomic) UIButton *closeCardsViewButton;
@property (nonatomic) UIButton *skipAllButton;
@property (nonatomic) UILabel *noTransactionsTitle;
@property (nonatomic) UILabel *noTransactionsDescription;
@property (nonatomic) UIButton *getBitcoinButton;
@property (nonatomic) CGRect originalHeaderFrame;
@property (nonatomic) UIScrollView *cardsScrollView;
@property (nonatomic) UIView *cardsView;

@property (nonatomic) UIView *noTransactionsView;
@end

@implementation TransactionsViewController

@synthesize data;
@synthesize latestBlock;

CGFloat cardsViewHeight = 240;

BOOL animateNextCell;
BOOL hasZeroTotalBalance = NO;
BOOL showCards;

UIRefreshControl *refreshControl;
int lastNumberTransactions = INT_MAX;

- (NSInteger)tableView:(UITableView *)_tableView numberOfRowsInSection:(NSInteger)section
{
    NSInteger transactionCount = [data.transactions count];
#if defined(ENABLE_TRANSACTION_FILTERING) && defined(ENABLE_TRANSACTION_FETCHING)
    if (data != nil && transactionCount == 0 && !self.loadedAllTransactions && self.clickedFetchMore) {
        [app.wallet fetchMoreTransactions];
    }
#endif
    return transactionCount;
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
    self.lastSelectedIndexPath = indexPath;
    
    TransactionTableCell *cell = (TransactionTableCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    [self showTransactionDetail:cell.transaction];
    [self.tableView deselectRowAtIndexPath:indexPath animated:YES];
}

- (void)tableView:(UITableView *)_tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
#if defined(ENABLE_TRANSACTION_FILTERING) && defined(ENABLE_TRANSACTION_FETCHING)
    if (!self.loadedAllTransactions) {
        if (indexPath.row == (int)[data.transactions count] - 1) {
            // If user scrolled down at all or if the user clicked fetch more and the table isn't filled, fetch
            if (_tableView.contentOffset.y > 0 || (_tableView.contentOffset.y <= 0 && self.clickedFetchMore)) {
                [app.wallet fetchMoreTransactions];
            } else {
                [self showMoreButton];
            }
        } else {
            [self hideMoreButton];
        }
    }
#endif
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
    showCards = ![[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_SHOULD_HIDE_ALL_CARDS];
    
    [self setupNoTransactionsView];
    
    if (showCards && app.latestResponse.symbol_local) {
        [self setupCardsView];
    } else {
        if (self.cardsView) {
            [self resetHeaderFrame];
            [self setupNoTransactionsView];
        }
        [self.cardsView removeFromSuperview];
        self.cardsView = nil;
    }
    
    BOOL shouldShowFilterButton = ([app.wallet didUpgradeToHd] && ([[app.wallet activeLegacyAddresses] count] > 0 || [app.wallet getActiveAccountsCount] >= 2));
    
    filterAccountButton.hidden = !shouldShowFilterButton;
    
    // Data not loaded yet
    if (!self.data) {
        self.noTransactionsView.hidden = YES;
        
#ifdef ENABLE_TRANSACTION_FILTERING
        self.filterIndex = FILTER_INDEX_ALL;
#endif
        
        [balanceBigButton setTitle:@"" forState:UIControlStateNormal];
        [self changeFilterLabel:@""];
    }
    // Data loaded, but no transactions yet
    else if (self.data.transactions.count == 0) {
        self.noTransactionsView.hidden = NO;
        
#if defined(ENABLE_TRANSACTION_FILTERING) && defined(ENABLE_TRANSACTION_FETCHING)
        if (!self.loadedAllTransactions) {
            [self showMoreButton];
        } else {
            [self hideMoreButton];
        }
#endif
        // Balance
        [balanceBigButton setTitle:[NSNumberFormatter formatMoney:[self getBalance] localCurrency:app->symbolLocal] forState:UIControlStateNormal];
        [self changeFilterLabel:[self getFilterLabel]];

    }
    // Data loaded and we have a balance - display the balance and transactions
    else {
        self.noTransactionsView.hidden = YES;
        
        // Balance
        [balanceBigButton setTitle:[NSNumberFormatter formatMoney:[self getBalance] localCurrency:app->symbolLocal] forState:UIControlStateNormal];
        [self changeFilterLabel:[self getFilterLabel]];
    }
}

- (void)showMoreButton
{
    self.moreButton.frame = CGRectMake(0, 0, self.view.frame.size.width, 50);
    self.moreButton.center = CGPointMake(self.view.frame.size.width/2, self.view.frame.size.height - self.moreButton.frame.size.height/2);
    self.moreButton.hidden = NO;
}

- (void)hideMoreButton
{
    self.moreButton.hidden = YES;
}

- (void)fetchMoreClicked
{
    self.clickedFetchMore = YES;
    [self reload];
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
    [self reloadData];
    
    [self.detailViewController didGetHistory];
}

- (void)reloadData
{
    [self setText];
    
    [tableView reloadData];
    
    [self reloadNewTransactions];
    
    [self animateFirstCell];
    
    [self reloadLastNumberOfTransactions];
    
    // This should be done when request has finished but there is no callback
    if (refreshControl && refreshControl.isRefreshing) {
        [refreshControl endRefreshing];
    }
}

- (void)reloadSymbols
{
    [self reloadData];
    
    [self.detailViewController reloadSymbols];
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
        [self performSelector:@selector(paymentReceived) withObject:nil afterDelay:0.1f];
    } else {
        hasZeroTotalBalance = [app.wallet getTotalActiveBalance] == 0;
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

#if defined(ENABLE_TRANSACTION_FILTERING) && defined(ENABLE_TRANSACTION_FETCHING)
    if (self.loadedAllTransactions) {
        self.loadedAllTransactions = NO;
        self.clickedFetchMore = YES;
        [app.wallet getHistory];
    } else {
        BOOL tableViewIsEmpty = [self.tableView numberOfRowsInSection:0] == 0;
        BOOL tableViewIsFilled = ![[self.tableView indexPathsForVisibleRows] containsObject:[NSIndexPath indexPathForRow:[data.transactions count] - 1 inSection:0]];
        
        if (tableViewIsEmpty) {
            [self fetchMoreClicked];
        } else if (tableViewIsFilled) {
            self.clickedFetchMore = YES;
           [app.wallet getHistory];
        } else {
           [self fetchMoreClicked];
        }
    }
#else
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_LOADING_TRANSACTIONS];
    
    [app.wallet performSelector:@selector(getHistory) withObject:nil afterDelay:0.1f];
#endif
}

- (NSDecimalNumber *)getAmountForReceivedTransaction:(Transaction *)transaction
{
    NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:ABS(transaction.amount)] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:SATOSHI]];
    DLog(@"TransactionsViewController: getting amount for received transaction");
    return number;
}

- (void)paymentReceived
{
    Transaction *transaction = [data.transactions firstObject];
    if ([transaction.txType isEqualToString:TX_TYPE_SENT]) return;
    
    BOOL shouldShowBackupReminder = (hasZeroTotalBalance && [app.wallet getTotalActiveBalance] > 0 &&
                             [transaction.txType isEqualToString:TX_TYPE_RECEIVED] &&
                             ![app.wallet isRecoveryPhraseVerified]);
    
    [app paymentReceived:[self getAmountForReceivedTransaction:transaction] showBackupReminder:shouldShowBackupReminder];
}

- (void)showTransactionDetailForHash:(NSString *)hash
{
    for (Transaction *transaction in data.transactions) {
        if ([transaction.myHash isEqualToString:hash]) {
            [self showTransactionDetail:transaction];
            break;
        }
    }
}

- (void)showTransactionDetail:(Transaction *)transaction
{
    TransactionDetailViewController *detailViewController = [TransactionDetailViewController new];
    detailViewController.transaction = transaction;
    
    TransactionDetailNavigationController *navigationController = [[TransactionDetailNavigationController alloc] initWithRootViewController:detailViewController];
    navigationController.transactionHash = transaction.myHash;
    
    detailViewController.busyViewDelegate = navigationController;
    navigationController.onDismiss = ^() {
        app.transactionsViewController.detailViewController = nil;
    };
    navigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    app.transactionsViewController.detailViewController = detailViewController;
    
    if (app.topViewControllerDelegate) {
        [app.topViewControllerDelegate presentViewController:navigationController animated:YES completion:nil];
    } else {
        [app.tabViewController presentViewController:navigationController animated:YES completion:nil];
    }
}

- (void)changeFilterLabel:(NSString *)newText
{
    [filterAccountButton setTitle:newText forState:UIControlStateNormal];
    
    if (newText.length > 0) {
        CGFloat currentCenterY = filterAccountButton.center.y;
        [filterAccountButton sizeToFit];
        filterAccountButton.center = CGPointMake(self.view.center.x, currentCenterY);
        
        filterAccountChevronButton.frame = CGRectMake(filterAccountButton.frame.origin.x + filterAccountButton.frame.size.width, filterAccountButton.frame.origin.y, filterAccountButton.frame.size.height, filterAccountButton.frame.size.height);
    }
    
    filterAccountChevronButton.hidden = filterAccountButton.hidden;
}

- (CGFloat)heightForFilterTableView
{
    CGFloat estimatedHeight = 44 * ([app.wallet getActiveAccountsCount] + 2);
    CGFloat largestAcceptableHeight = [[UIScreen mainScreen] bounds].size.height - 150;
    return estimatedHeight > largestAcceptableHeight ? largestAcceptableHeight : estimatedHeight;
}

- (uint64_t)getBalance
{
#ifdef ENABLE_TRANSACTION_FILTERING
    if (self.filterIndex == FILTER_INDEX_ALL) {
        return [app.wallet getTotalActiveBalance];
    } else if (self.filterIndex == FILTER_INDEX_IMPORTED_ADDRESSES) {
        return [app.wallet getTotalBalanceForActiveLegacyAddresses];
    } else {
        return [app.wallet getBalanceForAccount:(int)self.filterIndex];
    }
#else
    return [app.wallet getTotalActiveBalance];
#endif
}

- (NSString *)getFilterLabel
{
#ifdef ENABLE_TRANSACTION_FILTERING
    if (self.filterIndex == FILTER_INDEX_ALL) {
        return BC_STRING_TOTAL_BALANCE;
    } else if (self.filterIndex == FILTER_INDEX_IMPORTED_ADDRESSES) {
        return BC_STRING_IMPORTED_ADDRESSES;
    } else {
        return [app.wallet getLabelForAccount:(int)self.filterIndex];
    }
#else
    return nil;
#endif
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller
{
    return UIModalPresentationNone;
}

- (void)showFilterMenu
{
    BCAddressSelectionView *filterView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet selectMode:SelectModeFilter];
    filterView.delegate = self;
    [app showModalWithContent:filterView closeType:ModalCloseTypeBack headerText:BC_STRING_BALANCES];
}

#pragma mark - Address Selection Delegate

- (void)didSelectFromAccount:(int)account
{
    if (account == FILTER_INDEX_IMPORTED_ADDRESSES) {
        [app filterTransactionsByImportedAddresses];
    } else {
        [app filterTransactionsByAccount:account];
    }
}

- (void)didSelectToAddress:(NSString *)address
{
    DLog(@"TransactionsViewController Warning: filtering by single imported address!")
}

- (void)didSelectToAccount:(int)account
{
    DLog(@"TransactionsViewController Warning: selected to account!")
}

- (void)didSelectFromAddress:(NSString *)address
{
    DLog(@"TransactionsViewController Warning: selected from address!")
}

#pragma mark - View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.loadedAllTransactions = NO;
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT);
    
    self.originalHeaderFrame = headerView.frame;
    headerView.clipsToBounds = YES;
    
    showCards = ![[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_SHOULD_HIDE_ALL_CARDS];
    
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.scrollsToTop = YES;
    
    [balanceBigButton.titleLabel setMinimumScaleFactor:.5f];
    [balanceBigButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    
    [balanceBigButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
    
#if defined(ENABLE_TRANSACTION_FILTERING) && defined(ENABLE_TRANSACTION_FETCHING)
    
    self.moreButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [self.moreButton setTitle:BC_STRING_LOAD_MORE_TRANSACTIONS forState:UIControlStateNormal];
    self.moreButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.moreButton.backgroundColor = [UIColor whiteColor];
    [self.moreButton setTitleColor:COLOR_BLOCKCHAIN_BLUE forState:UIControlStateNormal];
    [self.view addSubview:self.moreButton];
    [self.moreButton addTarget:self action:@selector(fetchMoreClicked) forControlEvents:UIControlEventTouchUpInside];
    self.moreButton.hidden = YES;
#endif
    
    [self setupBlueBackgroundForBounceArea];
    
    [self setupPullToRefresh];
    
#ifdef ENABLE_TRANSACTION_FILTERING
    
    [filterAccountButton.titleLabel setMinimumScaleFactor:.5f];
    [filterAccountButton.titleLabel setAdjustsFontSizeToFitWidth:YES];
    [filterAccountButton addTarget:self action:@selector(showFilterMenu) forControlEvents:UIControlEventTouchUpInside];
    [filterAccountChevronButton addTarget:self action:@selector(showFilterMenu) forControlEvents:UIControlEventTouchUpInside];
    filterAccountChevronButton.imageView.transform = CGAffineTransformMakeScale(-1, 1);
    filterAccountChevronButton.imageEdgeInsets = UIEdgeInsetsMake(9, 4, 8, 12);

    self.filterIndex = FILTER_INDEX_ALL;
#else
    filterAccountButton.hidden = YES;
#endif
    
    [self reload];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    app.mainTitleLabel.hidden = YES;
    app.mainTitleLabel.adjustsFontSizeToFitWidth = YES;
    
    balanceBigButton.center = CGPointMake(headerView.center.x, balanceBigButton.center.y);
}

- (void)viewDidDisappear:(BOOL)animated
{
    [super viewDidDisappear:animated];
#ifdef ENABLE_TRANSACTION_FILTERING
    app.wallet.isFetchingTransactions = NO;
#endif
    app.mainTitleLabel.hidden = NO;
}

#pragma mark - Setup

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

- (void)setupCardsView
{
    [self.cardsView removeFromSuperview];
    UIView *cardsView = [[UIView alloc] initWithFrame:CGRectMake(self.tableView.frame.origin.x, self.tableView.frame.origin.y + self.originalHeaderFrame.size.height, self.originalHeaderFrame.size.width, cardsViewHeight)];
    headerView.frame = CGRectMake(self.originalHeaderFrame.origin.x, self.originalHeaderFrame.origin.y, self.originalHeaderFrame.size.width, self.originalHeaderFrame.size.height + cardsViewHeight);
    self.cardsView = [self configureCardsView:cardsView];
    
    [headerView addSubview:self.cardsView];
}

- (void)setupNoTransactionsView
{
    [self.noTransactionsView removeFromSuperview];
    
    CGFloat noTransactionsViewOffsetY = 0;
    
    // Special case for iPad/iPhone 4S screens - increase content size to give more space for noTransactionsView under cards view
    if ([[UIScreen mainScreen] bounds].size.height <= HEIGHT_IPHONE_4S && showCards) {
        self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 120, 0);
        noTransactionsViewOffsetY += 60;
    }
    
    self.noTransactionsView = [[UIView alloc] initWithFrame:CGRectMake(self.view.frame.origin.x, self.originalHeaderFrame.size.height + (showCards ? cardsViewHeight : 0) + noTransactionsViewOffsetY, self.view.frame.size.width, self.view.frame.size.height)];
    
    // Title label Y origin will be above midpoint between end of cards view and table view height
    UILabel *noTransactionsTitle = [[UILabel alloc] initWithFrame:CGRectZero];
    noTransactionsTitle.textAlignment = NSTextAlignmentCenter;
    noTransactionsTitle.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL_MEDIUM];
    noTransactionsTitle.text = BC_STRING_NO_TRANSACTIONS_TITLE;
    noTransactionsTitle.textColor = COLOR_BLOCKCHAIN_BLUE;
    [noTransactionsTitle sizeToFit];
    CGFloat noTransactionsViewCenterY = (tableView.frame.size.height - self.noTransactionsView.frame.origin.y)/2 - noTransactionsTitle.frame.size.height;
    noTransactionsTitle.center = CGPointMake(self.noTransactionsView.center.x, noTransactionsViewCenterY);
    [self.noTransactionsView addSubview:noTransactionsTitle];
    self.noTransactionsTitle = noTransactionsTitle;
    
    // Description label Y origin will be 8 points under title label
    UILabel *noTransactionsDescription = [[UILabel alloc] initWithFrame:CGRectZero];
    noTransactionsDescription.textAlignment = NSTextAlignmentCenter;
    noTransactionsDescription.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
    noTransactionsDescription.numberOfLines = 0;
    noTransactionsDescription.text = BC_STRING_NO_TRANSACTIONS_TEXT;
    noTransactionsDescription.textColor = COLOR_TEXT_DARK_GRAY;
    [noTransactionsDescription sizeToFit];
    CGSize labelSize = [noTransactionsDescription sizeThatFits:CGSizeMake(170, CGFLOAT_MAX)];
    CGRect labelFrame = noTransactionsDescription.frame;
    labelFrame.size = labelSize;
    noTransactionsDescription.frame = labelFrame;
    [self.noTransactionsView addSubview:noTransactionsDescription];
    noTransactionsDescription.center = CGPointMake(self.noTransactionsView.center.x, noTransactionsDescription.center.y);
    noTransactionsDescription.frame = CGRectMake(noTransactionsDescription.frame.origin.x, noTransactionsTitle.frame.origin.y + noTransactionsTitle.frame.size.height + 8, noTransactionsDescription.frame.size.width, noTransactionsDescription.frame.size.height);
    self.noTransactionsDescription = noTransactionsDescription;
    
    // Get bitcoin button Y origin will be 16 points under description label
    self.getBitcoinButton = [[UIButton alloc] initWithFrame:CGRectMake(0, noTransactionsDescription.frame.origin.y + noTransactionsDescription.frame.size.height + 16, 130, 30)];
    self.getBitcoinButton.clipsToBounds = YES;
    self.getBitcoinButton.layer.cornerRadius = CORNER_RADIUS_BUTTON;
    self.getBitcoinButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    self.getBitcoinButton.center = CGPointMake(self.noTransactionsView.center.x, self.getBitcoinButton.center.y);
    self.getBitcoinButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
    [self.getBitcoinButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.getBitcoinButton setTitle:[BC_STRING_GET_BITCOIN uppercaseString] forState:UIControlStateNormal];
    [self.getBitcoinButton addTarget:self action:@selector(getBitcoinButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.noTransactionsView addSubview:self.getBitcoinButton];
    
    if (!showCards) {
        [self centerNoTransactionSubviews];
    } else {
        self.getBitcoinButton.hidden = YES;
    }
    
    [tableView addSubview:self.noTransactionsView];
    
    self.noTransactionsView.hidden = YES;
}

#pragma mark - New Wallet Cards

- (UIView *)configureCardsView:(UIView *)cardsView
{
    cardsView.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    
    UIScrollView *scrollView = [[UIScrollView alloc] initWithFrame:cardsView.bounds];
    scrollView.delegate = self;
    scrollView.pagingEnabled = YES;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.scrollEnabled = YES;
    
    NSInteger numberOfPages = 1;
    NSInteger numberOfCards = 0;
    
    // Cards setup
    if ([app.wallet isBuyEnabled]) {
        
        NSString *tickerText = [NSString stringWithFormat:@"%@ = %@", [NSNumberFormatter formatBTC:[CURRENCY_CONVERSION_BTC longLongValue]], [NSNumberFormatter formatMoney:SATOSHI localCurrency:YES]];
        
        BCCardView *priceCard = [[BCCardView alloc] initWithContainerFrame:cardsView.bounds title:[NSString stringWithFormat:@"%@\n%@", BC_STRING_OVERVIEW_MARKET_PRICE_TITLE, tickerText] description:BC_STRING_OVERVIEW_MARKET_PRICE_DESCRIPTION actionType:ActionTypeBuyBitcoin imageName:@"btc_partial" delegate:self];
        [scrollView addSubview:priceCard];
        numberOfCards++;
        numberOfPages++;
    }

    BCCardView *receiveCard = [[BCCardView alloc] initWithContainerFrame:cardsView.bounds title:BC_STRING_OVERVIEW_RECEIVE_BITCOIN_TITLE description:BC_STRING_OVERVIEW_RECEIVE_BITCOIN_DESCRIPTION actionType:ActionTypeShowReceive imageName:@"receive_partial" delegate:self];
    receiveCard.frame = CGRectOffset(receiveCard.frame, [self getPageXPosition:cardsView.frame.size.width page:numberOfCards], 0);
    [scrollView addSubview:receiveCard];
    numberOfCards++;
    numberOfPages++;

    BCCardView *QRCard = [[BCCardView alloc] initWithContainerFrame:cardsView.bounds title:BC_STRING_OVERVIEW_QR_CODES_TITLE description:BC_STRING_OVERVIEW_QR_CODES_DESCRIPTION actionType:ActionTypeScanQR imageName:@"qr_partial" delegate:self];
    QRCard.frame = CGRectOffset(QRCard.frame, [self getPageXPosition:cardsView.frame.size.width page:numberOfCards], 0);
    [scrollView addSubview:QRCard];
    numberOfCards++;
    numberOfPages++;
    
    // Overview complete/last page setup
    CGFloat overviewCompleteCenterX = cardsView.frame.size.width/2 + [self getPageXPosition:cardsView.frame.size.width page:numberOfCards];
    
    UIImageView *checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 40, 40, 40)];
    checkImageView.image = [[UIImage imageNamed:@"success"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
    checkImageView.tintColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    checkImageView.center = CGPointMake(overviewCompleteCenterX, checkImageView.center.y);
    [scrollView addSubview:checkImageView];
    
    UILabel *doneTitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, checkImageView.frame.origin.y + checkImageView.frame.size.height + 14, 150, 30)];
    doneTitleLabel.textAlignment = NSTextAlignmentCenter;
    doneTitleLabel.textColor = COLOR_BLOCKCHAIN_BLUE;
    doneTitleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM_LARGE];
    doneTitleLabel.adjustsFontSizeToFitWidth = YES;
    doneTitleLabel.text = BC_STRING_OVERVIEW_COMPLETE_TITLE;
    doneTitleLabel.center = CGPointMake(overviewCompleteCenterX, doneTitleLabel.center.y);
    [scrollView addSubview:doneTitleLabel];
    
    UILabel *doneDescriptionLabel = [[UILabel alloc] initWithFrame:CGRectZero];
    doneDescriptionLabel.textAlignment = NSTextAlignmentCenter;
    doneDescriptionLabel.numberOfLines = 0;
    doneDescriptionLabel.textColor = COLOR_TEXT_DARK_GRAY;
    doneDescriptionLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
    doneDescriptionLabel.adjustsFontSizeToFitWidth = YES;
    doneDescriptionLabel.text = BC_STRING_OVERVIEW_COMPLETE_DESCRIPTION;
    [doneDescriptionLabel sizeToFit];
    CGFloat maxDoneDescriptionLabelWidth = 170;
    CGFloat maxDoneDescriptionLabelHeight = 70;
    CGSize labelSize = [doneDescriptionLabel sizeThatFits:CGSizeMake(maxDoneDescriptionLabelWidth, maxDoneDescriptionLabelHeight)];
    CGRect labelFrame = doneDescriptionLabel.frame;
    labelFrame.size = labelSize;
    doneDescriptionLabel.frame = labelFrame;
    doneDescriptionLabel.frame = CGRectMake(0, doneTitleLabel.frame.origin.y + doneTitleLabel.frame.size.height, doneDescriptionLabel.frame.size.width, doneDescriptionLabel.frame.size.height);
    doneDescriptionLabel.center = CGPointMake(overviewCompleteCenterX, doneDescriptionLabel.center.y);
    [scrollView addSubview:doneDescriptionLabel];
    
    scrollView.contentSize = CGSizeMake(cardsView.frame.size.width * (numberOfPages), cardsView.frame.size.height);
    [cardsView addSubview:scrollView];
    self.cardsScrollView = scrollView;
    
    // Subviews that disappear/reappear setup
    CGRect cardRect = [BCCardView frameFromContainer:cardsView.bounds];
    
    self.pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, cardRect.origin.y + cardRect.size.height + 8, 100, 30)];
    self.pageControl.center = CGPointMake(cardsView.center.x, self.pageControl.center.y);
    self.pageControl.numberOfPages = numberOfCards;
    self.pageControl.currentPageIndicatorTintColor = COLOR_BLOCKCHAIN_BLUE;
    self.pageControl.pageIndicatorTintColor = COLOR_BLOCKCHAIN_LIGHTEST_BLUE;
    [self.pageControl addTarget:self action:@selector(pageControlChanged:) forControlEvents:UIControlEventValueChanged];
    [cardsView addSubview:self.pageControl];
    
    self.startOverButton = [[UIButton alloc] initWithFrame:CGRectInset(self.pageControl.frame, -40, -10)];
    [cardsView addSubview:self.startOverButton];
    [self.startOverButton setTitle:BC_STRING_START_OVER forState:UIControlStateNormal];
    [self.startOverButton setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateNormal];
    self.startOverButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
    self.startOverButton.hidden = YES;
    [self.startOverButton addTarget:self action:@selector(showFirstCard) forControlEvents:UIControlEventTouchUpInside];
    
    CGFloat closeButtonHeight = 46;
    self.closeCardsViewButton = [[UIButton alloc] initWithFrame:CGRectMake(cardsView.frame.size.width - closeButtonHeight, 0, closeButtonHeight, closeButtonHeight)];
    self.closeCardsViewButton.imageEdgeInsets = UIEdgeInsetsMake(16, 20, 16, 12);
    [self.closeCardsViewButton setImage:[[UIImage imageNamed:@"close"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
    self.closeCardsViewButton.imageView.tintColor = COLOR_LIGHT_GRAY;
    [self.closeCardsViewButton addTarget:self action:@selector(closeCardsView) forControlEvents:UIControlEventTouchUpInside];
    [cardsView addSubview:self.closeCardsViewButton];
    self.closeCardsViewButton.hidden = YES;
    
    CGFloat skipAllButtonWidth = 80;
    CGFloat skipAllButtonHeight = 30;
    self.skipAllButton = [[UIButton alloc] initWithFrame:CGRectMake(cardsView.frame.size.width - skipAllButtonWidth, self.pageControl.frame.origin.y, skipAllButtonWidth, skipAllButtonHeight)];
    self.skipAllButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
    self.skipAllButton.backgroundColor = [UIColor clearColor];
    [self.skipAllButton setTitleColor:COLOR_BLOCKCHAIN_LIGHTEST_BLUE forState:UIControlStateNormal];
    [self.skipAllButton setTitle:BC_STRING_SKIP_ALL forState:UIControlStateNormal];
    [self.skipAllButton addTarget:self action:@selector(closeCardsView) forControlEvents:UIControlEventTouchUpInside];
    [cardsView addSubview:self.skipAllButton];
    
    
    // Maintain last viewed page when a refresh is triggered
    CGFloat oldContentOffsetX = [[[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_LAST_CARD_OFFSET] floatValue];
    if (oldContentOffsetX > scrollView.contentSize.width - scrollView.frame.size.width * 1.5) {
        self.startOverButton.hidden = NO;
        self.closeCardsViewButton.hidden = NO;
        self.pageControl.hidden = YES;
        self.skipAllButton.hidden = YES;
    };
    self.cardsScrollView.contentOffset = CGPointMake(oldContentOffsetX > self.cardsScrollView.contentSize.width ? self.cardsScrollView.contentSize.width - self.cardsScrollView.frame.size.width : oldContentOffsetX, self.cardsScrollView.contentOffset.y);
    
    return cardsView;
}

- (CGFloat)getPageXPosition:(CGFloat)cardLength page:(NSInteger)page
{
    return cardLength * page;
}

- (void)showFirstCard
{
    self.cardsScrollView.scrollEnabled = YES;
    [self.cardsScrollView setContentOffset:CGPointZero animated:YES];
    
    [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:0] forKey:USER_DEFAULTS_KEY_LAST_CARD_OFFSET];
}

- (void)cardActionClicked:(ActionType)actionType
{
    if (actionType == ActionTypeBuyBitcoin) {
        [app buyBitcoinClicked:nil];
    } else if (actionType == ActionTypeShowReceive) {
        [app receiveCoinClicked:nil];
    } else if (actionType == ActionTypeScanQR) {
        [app QRCodebuttonClicked:nil];
    }
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.cardsScrollView) {
        
        BOOL didSeeAllCards = scrollView.contentOffset.x > scrollView.contentSize.width - scrollView.frame.size.width * 1.5;
        if (didSeeAllCards) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_KEY_HAS_SEEN_ALL_CARDS];
        }
        
        if (!self.isUsingPageControl) {
            CGFloat pageWidth = scrollView.frame.size.width;
            float fractionalPage = scrollView.contentOffset.x / pageWidth;
            
            if (!didSeeAllCards) {
                if (self.skipAllButton.hidden && self.pageControl.hidden) {
                    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                        self.skipAllButton.alpha = 1;
                        self.pageControl.alpha = 1;
                        self.startOverButton.alpha = 0;
                        self.closeCardsViewButton.alpha = 0;
                    } completion:^(BOOL finished) {
                        self.skipAllButton.hidden = NO;
                        self.pageControl.hidden = NO;
                        self.startOverButton.hidden = YES;
                        self.closeCardsViewButton.hidden = YES;
                    }];
                }
            } else {
                if (!self.skipAllButton.hidden && !self.pageControl.hidden) {
                    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                        self.skipAllButton.alpha = 0;
                        self.pageControl.alpha = 0;
                        self.startOverButton.alpha = 1;
                        self.closeCardsViewButton.alpha = 1;
                    } completion:^(BOOL finished) {
                        self.skipAllButton.hidden = YES;
                        self.pageControl.hidden = YES;
                        self.startOverButton.hidden = NO;
                        self.closeCardsViewButton.hidden = NO;
                    }];
                }
            }
            
            NSInteger page = lround(fractionalPage);
            self.pageControl.currentPage = page;
        }
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView == self.cardsScrollView) {
        if (scrollView.contentSize.width - scrollView.frame.size.width <= scrollView.contentOffset.x) {
            scrollView.scrollEnabled = NO;
        }
    
        // Save last viewed page since cards view can be reinstantiated when app is still open
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithFloat:scrollView.contentOffset.x] forKey:USER_DEFAULTS_KEY_LAST_CARD_OFFSET];
    }
}

- (void)scrollViewDidEndScrollingAnimation:(UIScrollView *)scrollView
{
    if (scrollView == self.cardsScrollView) {
        self.isUsingPageControl = NO;
    }
}

- (void)pageControlChanged:(UIPageControl *)pageControl
{
    self.isUsingPageControl = YES;
    
    NSInteger page = pageControl.currentPage;
    CGRect frame = self.cardsScrollView.frame;
    frame.origin.x = self.cardsScrollView.frame.size.width * page;
    [self.cardsScrollView scrollRectToVisible:frame animated:YES];
}

- (void)closeCardsView
{
    self.getBitcoinButton.alpha = 0;

    [UIView animateWithDuration:ANIMATION_DURATION_LONG animations:^{

        [self resetHeaderFrame];
        
        [self centerNoTransactionSubviews];
        
        self.getBitcoinButton.hidden = NO;
        self.getBitcoinButton.alpha = 1;
        
    }];
    
    [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_KEY_SHOULD_HIDE_ALL_CARDS];
    
    [self.tableView reloadData];
}

- (void)centerNoTransactionSubviews
{
    // Reposition description label Y to center of screen, and reposition title and button Y origins around it
    self.noTransactionsDescription.center = CGPointMake(self.noTransactionsTitle.center.x, self.noTransactionsView.frame.size.height/2 - self.originalHeaderFrame.size.height);
    self.noTransactionsTitle.center = CGPointMake(self.noTransactionsTitle.center.x, self.noTransactionsDescription.frame.origin.y - self.noTransactionsTitle.frame.size.height - 8 + self.noTransactionsTitle.frame.size.height/2);
    self.getBitcoinButton.center = CGPointMake(self.getBitcoinButton.center.x, self.noTransactionsDescription.frame.origin.y + self.noTransactionsDescription.frame.size.height + 16 + self.noTransactionsDescription.frame.size.height/2);
    self.getBitcoinButton.hidden = NO;
}

- (void)resetHeaderFrame
{
    CGRect headerFrame = self.originalHeaderFrame;
    headerFrame.size.height = 80;
    headerView.frame = headerFrame;
    
    self.noTransactionsView.frame = CGRectOffset(self.noTransactionsView.frame, 0, -cardsViewHeight);
}

- (void)getBitcoinButtonClicked
{
    if ([app.wallet isBuyEnabled]) {
        [app buyBitcoinClicked:nil];
    } else {
        [app receiveCoinClicked:nil];
    }
}

@end

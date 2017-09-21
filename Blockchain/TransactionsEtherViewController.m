//
//  EtherTransactionsViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/30/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionsEtherViewController.h"
#import "RootService.h"
#import "TransactionEtherTableViewCell.h"
#import "EtherTransaction.h"

@interface TransactionsViewController ()
@property (nonatomic) UILabel *noTransactionsTitle;
@property (nonatomic) UILabel *noTransactionsDescription;
@property (nonatomic) UIButton *getBitcoinButton;

@property (nonatomic) UIView *noTransactionsView;

- (void)setupNoTransactionsViewInView:(UIView *)view assetType:(AssetType)assetType;
@end

@interface TransactionsEtherViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NSArray *transactions;
@end

@implementation TransactionsEtherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0,
                                 TAB_HEADER_HEIGHT_DEFAULT - DEFAULT_HEADER_HEIGHT,
                                 app.window.frame.size.width,
                                 app.window.frame.size.height - TAB_HEADER_HEIGHT_DEFAULT - DEFAULT_FOOTER_HEIGHT);
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    
    [self setupPullToRefresh];
    
    [self setupNoTransactionsViewInView:self.tableView assetType:AssetTypeEther];
    
    [self loadTransactions];
}

- (void)reload
{
    [self loadTransactions];
}

- (void)reloadSymbols
{
    [self.tableView reloadData];
    
    [self.detailViewController reloadSymbols];
}

- (void)setupPullToRefresh
{
    // Tricky way to get the refreshController to work on a UIViewController - @see http://stackoverflow.com/a/12502450/2076094
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                       action:@selector(getHistory)
             forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
}

- (void)getHistory
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_LOADING_TRANSACTIONS];
    
    [app.wallet performSelector:@selector(getEthHistory) withObject:nil afterDelay:0.1f];
}

- (void)loadTransactions
{
    self.transactions = [app.wallet getEthTransactions];
    
    self.noTransactionsView.hidden = self.transactions.count > 0;
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

#pragma mark - Table View Data Source

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.transactions.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TransactionEtherTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"transaction"];

    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"TransactionEtherCell" owner:nil options:nil] objectAtIndex:0];
    }
    
    EtherTransaction *transaction = [EtherTransaction fromJSONDict:self.transactions[indexPath.row]];

    cell.transaction = transaction;
    
    [cell reload];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    TransactionEtherTableViewCell *cell = (TransactionEtherTableViewCell *)[self.tableView cellForRowAtIndexPath:indexPath];
    
    [cell transactionClicked];
}

@end

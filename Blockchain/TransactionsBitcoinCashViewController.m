//
//  TransactionsBitcoinCashViewController.m
//  Blockchain
//
//  Created by kevinwu on 2/21/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionsBitcoinCashViewController.h"
#import "RootService.h"
#import "TransactionTableCell.h"

@interface TransactionsBitcoinCashViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIRefreshControl *refreshControl;
@property (nonatomic) NSArray *transactions;
@end

@implementation TransactionsBitcoinCashViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0,
                                 DEFAULT_HEADER_HEIGHT_OFFSET,
                                 [UIScreen mainScreen].bounds.size.width,
                                 [UIScreen mainScreen].bounds.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_HEADER_HEIGHT_OFFSET - DEFAULT_FOOTER_HEIGHT);
    
    self.tableView = [[UITableView alloc] initWithFrame:self.view.bounds];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.tableView.tableFooterView = [[UIView alloc] init];
    [self.view addSubview:self.tableView];
    
    [self setupPullToRefresh];
//
//    [self setupNoTransactionsViewInView:self.tableView assetType:AssetTypeEther];
//
    [self loadTransactions];
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

- (void)loadTransactions
{
    self.transactions = [app.wallet bitcoinCashTransactions];
    
//    self.noTransactionsView.hidden = self.transactions.count > 0;
    
    [self.tableView reloadData];
    [self.refreshControl endRefreshing];
}

- (void)getHistory
{
    
}

#pragma mark - Table View Data Source

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    TransactionTableCell * cell = (TransactionTableCell*)[tableView dequeueReusableCellWithIdentifier:@"transaction"];
    
    Transaction * transaction = [self.transactions objectAtIndex:[indexPath row]];

    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"TransactionCell" owner:nil options:nil] objectAtIndex:0];
    }
    
    cell.transaction = transaction;
    
    [cell reload];
    
    cell.selectionStyle = UITableViewCellSelectionStyleDefault;
    
    cell.selectedBackgroundView = [self selectedBackgroundViewForCell:cell];
    
    return cell;
}

- (UIView *)selectedBackgroundViewForCell:(UITableViewCell *)cell
{
    // Selected cell color
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    return v;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 65;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.transactions.count;
}

@end

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
    [self.view addSubview:self.tableView];
    
    [self setupPullToRefresh];
    
    [self loadTransactions];
}

- (void)setupPullToRefresh
{
    // Tricky way to get the refreshController to work on a UIViewController - @see http://stackoverflow.com/a/12502450/2076094
    UITableViewController *tableViewController = [[UITableViewController alloc] init];
    tableViewController.tableView = self.tableView;
    self.refreshControl = [[UIRefreshControl alloc] init];
    [self.refreshControl addTarget:self
                       action:@selector(loadTransactions)
             forControlEvents:UIControlEventValueChanged];
    tableViewController.refreshControl = self.refreshControl;
}

- (void)loadTransactions
{
    self.transactions = [app.wallet getEthTransactions];
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
    
    EtherTransaction *transaction = [EtherTransaction fromJSONDict:self.transactions[indexPath.row]];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"TransactionEtherCell" owner:nil options:nil] objectAtIndex:0];
    }
    
    return cell;
}

@end

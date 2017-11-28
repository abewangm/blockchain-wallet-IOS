//
//  ExchangeOverviewViewController.m
//  Blockchain
//
//  Created by kevinwu on 10/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeOverviewViewController.h"
#import "ExchangeCreateViewController.h"
#import "ExchangeProgressViewController.h"
#import "BCNavigationController.h"
#import "BCLine.h"
#import "ExchangeTableViewCell.h"
#import "RootService.h"

#import "ExchangeDetailView.h"

#define EXCHANGE_VIEW_HEIGHT 70
#define EXCHANGE_VIEW_OFFSET 30
#define CELL_HEIGHT 65

#define CELL_IDENTIFIER_EXCHANGE_CELL @"exchangeCell"

@interface ExchangeOverviewViewController () <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@property (nonatomic) NSArray *trades;
@property (nonatomic) ExchangeCreateViewController *createViewController;
@end

@implementation ExchangeOverviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    
    [self setupExchangeButtonView];
    
    [self setupTableView];
    
    [app.wallet getExchangeTrades];
}

- (void)setupExchangeButtonView
{
    CGFloat windowWidth = WINDOW_WIDTH;
    UIView *newExchangeView = [[UIView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT + EXCHANGE_VIEW_OFFSET, windowWidth, EXCHANGE_VIEW_HEIGHT)];
    newExchangeView.backgroundColor = [UIColor whiteColor];
    
    BCLine *topLine = [[BCLine alloc] initWithYPosition:newExchangeView.frame.origin.y - 1];
    [self.view addSubview:topLine];
    
    BCLine *bottomLine = [[BCLine alloc] initWithYPosition:newExchangeView.frame.origin.y + newExchangeView.frame.size.height];
    [self.view addSubview:bottomLine];
    
    CGFloat exchangeLabelOriginX = 80;
    CGFloat chevronWidth = 15;
    CGFloat exchangeLabelHeight = 30;
    UILabel *newExchangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(exchangeLabelOriginX, newExchangeView.frame.size.height/2 - exchangeLabelHeight/2, windowWidth - exchangeLabelOriginX - chevronWidth, exchangeLabelHeight)];
    newExchangeLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_MEDIUM];
    newExchangeLabel.text = BC_STRING_NEW_EXCHANGE;
    newExchangeLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [newExchangeView addSubview:newExchangeLabel];
    
    CGFloat exchangeIconImageViewWidth = 50;
    UIImageView *exchangeIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, newExchangeView.frame.size.height/2 - exchangeIconImageViewWidth/2, exchangeIconImageViewWidth, exchangeIconImageViewWidth)];
    exchangeIconImageView.backgroundColor = [UIColor greenColor];
    [newExchangeView addSubview:exchangeIconImageView];
    
    UIImageView *chevronImageView = [[UIImageView alloc] initWithFrame:CGRectMake(newExchangeView.frame.size.width - 8 - chevronWidth, newExchangeView.frame.size.height/2 - chevronWidth/2, chevronWidth, chevronWidth)];
    chevronImageView.image = [UIImage imageNamed:@"chevron_right"];
    chevronImageView.contentMode = UIViewContentModeScaleAspectFit;
    chevronImageView.tintColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    [newExchangeView addSubview:chevronImageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(newExchangeClicked)];
    [newExchangeView addGestureRecognizer:tapGesture];
    
    [self.view addSubview:newExchangeView];
}

- (void)setupTableView
{
    CGFloat windowWidth = WINDOW_WIDTH;
    CGFloat yOrigin = DEFAULT_HEADER_HEIGHT + EXCHANGE_VIEW_OFFSET + EXCHANGE_VIEW_HEIGHT + 16;
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, yOrigin, windowWidth, self.view.frame.size.height - 16 - yOrigin) style:UITableViewStylePlain];
    tableView.delegate = self;
    tableView.dataSource = self;
    [self.view addSubview:tableView];
    self.tableView = tableView;
}

- (void)newExchangeClicked
{
    ExchangeCreateViewController *createViewController = [ExchangeCreateViewController new];
    [self.navigationController pushViewController:createViewController animated:YES];
    self.createViewController = createViewController;
}

- (void)didGetExchangeTrades:(NSArray *)trades
{
    self.trades = trades;
    [self.tableView reloadData];
}

- (void)didGetExchangeRate:(NSDictionary *)result
{
    [self.createViewController didGetExchangeRate:result];
}

- (void)didGetQuote:(NSDictionary *)result
{
    [self.createViewController didGetQuote:result];
}

- (void)didGetAvailableEthBalance:(NSDictionary *)result
{
    [self.createViewController didGetAvailableEthBalance:result];
}

- (void)didGetAvailableBtcBalance:(NSDictionary *)result
{
    [self.createViewController didGetAvailableBtcBalance:result];
}

#pragma mark - Table View Delegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.trades.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return CELL_HEIGHT;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    ExchangeTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_EXCHANGE_CELL];
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ExchangeTableViewCell" owner:nil options:nil] objectAtIndex:0];
        ExchangeTrade *trade = [self.trades objectAtIndex:indexPath.row];
        [cell configureWithTrade:trade];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ExchangeProgressViewController *exchangeProgressVC = [[ExchangeProgressViewController alloc] init];
    exchangeProgressVC.trade = [self.trades objectAtIndex:indexPath.row];
    BCNavigationController *navigationController = [[BCNavigationController alloc] initWithRootViewController:exchangeProgressVC title:BC_STRING_EXCHANGE];
    [self presentViewController:navigationController animated:YES completion:nil];
}

@end

//
//  ConfirmStateViewController.m
//  Blockchain
//
//  Created by kevinwu on 12/5/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ConfirmStateViewController.h"
#import "StateSelectorViewController.h"
#import "BCNavigationController.h"

@interface ConfirmStateViewController () <UITableViewDelegate, UITableViewDataSource, StateSelectorDelegate>
@property (nonatomic) NSArray *states;
@property (nonatomic) NSDictionary *selectedState;
@property (nonatomic) UITableView *tableView;
@end

@implementation ConfirmStateViewController

- (id)initWithStates:(NSArray *)states
{
    if (self == [super init]) {
        self.states = states;
        self.selectedState = [self.states firstObject];
    }
    
    return self;
}

- (void)viewDidLoad
{
    CGFloat windowWidth = WINDOW_WIDTH;
    CGFloat tableViewYPosition = DEFAULT_HEADER_HEIGHT;
    UITableView *oneRowTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, tableViewYPosition, windowWidth, self.view.frame.size.height - tableViewYPosition) style:UITableViewStyleGrouped];
    oneRowTableView.dataSource = self;
    oneRowTableView.delegate = self;
    [self.view addSubview:oneRowTableView];
    self.tableView = oneRowTableView;
}

- (void)viewWillAppear:(BOOL)animated
{
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    navigationController.headerTitle = BC_STRING_EXCHANGE;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] init];
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    cell.textLabel.text = self.selectedState[STATE_KEY_NAME];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 50;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat windowWidth = WINDOW_WIDTH;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, windowWidth, 50)];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 20, windowWidth, 30)];
    headerLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];;
    headerLabel.text = BC_STRING_SELECT_YOUR_STATE;
    [containerView addSubview:headerLabel];
    
    return containerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    StateSelectorViewController *stateSelectorController = [[StateSelectorViewController alloc] initWithStates:self.states];
    stateSelectorController.delegate = self;
    [self.navigationController pushViewController:stateSelectorController animated:YES];
}

#pragma mark - State selector delegate

- (void)didSelectState:(NSDictionary *)state
{
    self.selectedState = state;
    [self.tableView reloadData];
}

@end

//
//  ConfirmStateViewController.m
//  Blockchain
//
//  Created by kevinwu on 12/5/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ConfirmStateViewController.h"

@interface ConfirmStateViewController () <UITableViewDelegate, UITableViewDataSource>

@end

@implementation ConfirmStateViewController

- (void)viewDidLoad
{
    CGFloat windowWidth = WINDOW_WIDTH;
    CGFloat tableViewYPosition = DEFAULT_HEADER_HEIGHT;
    UITableView *oneRowTableView = [[UITableView alloc] initWithFrame:CGRectMake(0, tableViewYPosition, windowWidth, self.view.frame.size.height - tableViewYPosition) style:UITableViewStyleGrouped];
    oneRowTableView.dataSource = self;
    oneRowTableView.delegate = self;
    [self.view addSubview:oneRowTableView];
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
    cell.textLabel.text = @"test";
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 60;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    CGFloat windowWidth = WINDOW_WIDTH;
    
    UIView *containerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, windowWidth, 60)];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 0, windowWidth, 30)];
    headerLabel.center = CGPointMake(headerLabel.center.x, containerView.frame.size.height/2);
    headerLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];;
    headerLabel.text = BC_STRING_SELECT_YOUR_STATE;
    [containerView addSubview:headerLabel];
    
    return containerView;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
}

@end

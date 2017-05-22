//
//  BCFeeSelectionView.m
//  Blockchain
//
//  Created by kevinwu on 5/8/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCFeeSelectionView.h"
#import "FeeTableCell.h"

int numberOfRows = 3;

@interface BCFeeSelectionView()
@property (nonatomic) UITableView *tableView;
@end

@implementation BCFeeSelectionView

- (id)initWithFrame:(CGRect)rect
{
    if (self = [super initWithFrame:rect]) {
        [self setup];
    }
    return self;
}

- (void)setup
{
    self.tableView = [[UITableView alloc] initWithFrame:self.frame];
    self.tableView.tableFooterView = [UIView new];
    [self addSubview:self.tableView];
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [self.tableView reloadData];
}

#pragma mark - Table View Delegate

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    FeeTableCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"feeOption"];
    if (cell == nil) {
        FeeType feeType = indexPath.row == numberOfRows - 1 ? FeeTypeCustom : FeeTypeRegular;
        cell = [[FeeTableCell alloc] initWithFeeType:feeType];
        cell.backgroundColor = [UIColor whiteColor];
    }
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return numberOfRows;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 44.0f;
}

@end

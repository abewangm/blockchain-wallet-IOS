//
//  AssetSelectorView.m
//  Blockchain
//
//  Created by kevinwu on 2/14/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "AssetSelectorView.h"
#import "AssetSelectionTableViewCell.h"

#define CELL_IDENTIFIER_ASSET_SELECTOR @"assetSelectorCell"

@interface AssetSelectorView () <UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@end

@implementation AssetSelectorView

- (id)initWithFrame:(CGRect)frame delegate:(id<UITableViewDelegate>)delegate
{
    if (self == [super initWithFrame:frame]) {
        self.tableView = [[UITableView alloc] initWithFrame:frame];
        self.tableView.delegate = delegate;
        self.tableView.dataSource = self;
        [self.tableView registerClass:[AssetSelectionTableViewCell class] forCellReuseIdentifier:CELL_IDENTIFIER_ASSET_SELECTOR];
    }
    
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AssetSelectionTableViewCell *cell = (AssetSelectionTableViewCell *)[tableView dequeueReusableCellWithIdentifier:CELL_IDENTIFIER_ASSET_SELECTOR];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 3;
}

@end

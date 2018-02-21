//
//  AssetSelectorView.m
//  Blockchain
//
//  Created by kevinwu on 2/14/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "AssetSelectorView.h"
#import "AssetSelectionTableViewCell.h"
#import "UIView+ChangeFrameAttribute.h"

#define CELL_IDENTIFIER_ASSET_SELECTOR @"assetSelectorCell"

@interface AssetSelectorView () <UITableViewDataSource, UITableViewDelegate>
@property (nonatomic) UITableView *tableView;
@property (nonatomic, readwrite) BOOL isOpen;
@property (nonatomic, weak) id <AssetSelectorViewDelegate> delegate;
@end

@implementation AssetSelectorView

- (id)initWithFrame:(CGRect)frame delegate:(id<AssetSelectorViewDelegate>)delegate
{
    if (self == [super initWithFrame:frame]) {
        self.delegate = delegate;
        self.tableView = [[UITableView alloc] initWithFrame:frame];
        self.tableView.delegate = self;
        self.tableView.dataSource = self;
        [self addSubview:self.tableView];
        
        self.tableView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AssetSelectionTableViewCell *cell = [[AssetSelectionTableViewCell alloc] initWithAsset:indexPath.row];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.isOpen ? 3 : 1;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    AssetSelectionTableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    [self.delegate didSelectAsset:cell.assetType];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return ASSET_SELECTOR_ROW_HEIGHT;
}

- (void)hide
{
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self changeHeight:0];
    }];
}

- (void)show
{
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self changeHeight:ASSET_SELECTOR_ROW_HEIGHT];
    }];
}

- (void)open
{
    self.isOpen = YES;

    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.tableView reloadData];
        [self changeHeight:ASSET_SELECTOR_ROW_HEIGHT * 3];
        [self.tableView changeHeight:ASSET_SELECTOR_ROW_HEIGHT * 3];
    }];
}

- (void)close
{
    self.isOpen = NO;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.tableView reloadData];
        [self changeHeight:ASSET_SELECTOR_ROW_HEIGHT];
        [self.tableView changeHeight:ASSET_SELECTOR_ROW_HEIGHT];
    }];
}

- (void)selectorClicked
{
    [self open];
}

@end

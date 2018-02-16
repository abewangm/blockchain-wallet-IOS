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

@interface AssetSelectorView () <UITableViewDataSource>
@property (nonatomic) UITableView *tableView;
@property (nonatomic, readwrite) BOOL isOpen;
@end

@implementation AssetSelectorView

- (id)initWithFrame:(CGRect)frame delegate:(id<UITableViewDelegate>)delegate
{
    if (self == [super initWithFrame:frame]) {
        self.tableView = [[UITableView alloc] initWithFrame:frame];
        self.tableView.delegate = delegate;
        self.tableView.dataSource = self;
        [self addSubview:self.tableView];
        
        self.tableView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
        self.backgroundColor = [UIColor clearColor];
    }
    
    return self;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    AssetSelectionTableViewCell *cell = [[AssetSelectionTableViewCell alloc] initWithAsset:AssetTypeBitcoin];
    return cell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.isOpen ? 3 : 1;
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
        [self changeHeight:36];
    }];
}

- (void)open
{
    self.isOpen = YES;

    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.tableView reloadData];
        [self.tableView changeHeight:36 * [self tableView:self.tableView numberOfRowsInSection:0]];
    }];
}

- (void)close
{
    self.isOpen = NO;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        [self.tableView reloadData];
        [self.tableView changeHeight:36];
    }];
}

- (void)selectorClicked
{
    [self open];
}

@end

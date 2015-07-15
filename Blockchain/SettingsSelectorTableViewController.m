//
//  SettingsSelectorTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/14/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsSelectorTableViewController.h"

@interface SettingsSelectorTableViewController()
@property (nonatomic, copy) NSArray *keysArray;
@end

@implementation SettingsSelectorTableViewController

- (NSString *)getCurrencySymbolFromCode:(NSString *)code
{
    return @"";
}

- (void)setItemsDictionary:(NSDictionary *)itemsDictionary
{
    _itemsDictionary = itemsDictionary;
    self.keysArray = [[_itemsDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.keysArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    NSString *currencyCode = self.keysArray[indexPath.row];
    if ([currencyCode isEqualToString:self.currentCurrencySymbol.code]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@ (%@)", currencyCode, [self getCurrencySymbolFromCode:currencyCode]];
    cell.textLabel.text = self.itemsDictionary[currencyCode];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didDeselectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    
}


@end

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
@property (nonatomic, copy) NSArray *namesArray;
@property (nonatomic) CurrencySymbol *currentCurrencySymbol;
@property (nonatomic) NSString *selectedCurrencyCode;
@end

@implementation SettingsSelectorTableViewController

- (CurrencySymbol *)getLocalSymbolFromLatestResponse
{
    return app.latestResponse.symbol_local;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self.delegate selector:@selector(changeLocalCurrencySuccess) name:NOTIFICATION_KEY_CHANGE_LOCAL_CURRENCY_SUCCESS object:nil];
    [self changeCurrencySymbol:self.selectedCurrencyCode];
}

- (void)changeCurrencySymbol:(NSString *)code
{
    [app.wallet changeLocalCurrency:code];
}

- (void)setItemsDictionary:(NSDictionary *)itemsDictionary
{
    _itemsDictionary = itemsDictionary;
    self.keysArray = [_itemsDictionary allKeys];
    self.namesArray = [[_itemsDictionary allValues] sortedArrayUsingSelector:@selector(compare:)];
    
    self.currentCurrencySymbol = [self getLocalSymbolFromLatestResponse];
    
    self.selectedCurrencyCode = [self getLocalSymbolFromLatestResponse].code;
}

#pragma mark - Table view data source

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.keysArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:@"cell"];
    
    cell.textLabel.text = self.namesArray[indexPath.row];
    
    NSString *currencyCode = [[self.itemsDictionary allKeysForObject:cell.textLabel.text] firstObject];
    if ([currencyCode isEqualToString:self.selectedCurrencyCode]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *currencyCode = [[self.itemsDictionary allKeysForObject:self.namesArray[indexPath.row]] firstObject];
    
    self.selectedCurrencyCode = currencyCode;
    
    [self.tableView reloadData];
}

@end

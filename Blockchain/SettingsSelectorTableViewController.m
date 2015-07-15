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
@property (nonatomic) CurrencySymbol *currentCurrencySymbol;
@property (nonatomic) NSString *selectedCurrencyCode;
@end

@implementation SettingsSelectorTableViewController

- (NSString *)getCurrencySymbolFromCode:(NSString *)code
{
    return @"";
}

- (CurrencySymbol *)getLocalSymbolFromLatestResponse
{
    return app.latestResponse.symbol_local;
}

- (void)changeLocalCurrencySuccess
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:CHANGE_LOCAL_CURRENCY_SUCCESS_NOTIFICATION_KEY object:nil];
    [[NSUserDefaults standardUserDefaults] setValue:self.selectedCurrencyCode forKey:@"currency"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadData];
}

- (void)changeCurrencySymbol:(NSString *)code
{
    [app.wallet changeLocalCurrency:code];
}

- (void)setItemsDictionary:(NSDictionary *)itemsDictionary
{
    _itemsDictionary = itemsDictionary;
    self.keysArray = [[_itemsDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    self.currentCurrencySymbol = [self getLocalSymbolFromLatestResponse];
    
    // Currency preference is not set until returning from settings and updating the wallet, so store temporarily in NSUserDefaults for display purposes
    
    NSString *preferredCurrencySymbol = [[NSUserDefaults standardUserDefaults] valueForKey:@"currency"];
    self.selectedCurrencyCode = preferredCurrencySymbol == nil ? [self getLocalSymbolFromLatestResponse].code : preferredCurrencySymbol;
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
    if ([currencyCode isEqualToString:self.selectedCurrencyCode]) {
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
    }
    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@ (%@)", currencyCode, [self getCurrencySymbolFromCode:currencyCode]];
    cell.textLabel.text = self.itemsDictionary[currencyCode];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *currencyCode = self.keysArray[indexPath.row];
    
    self.selectedCurrencyCode = currencyCode;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeLocalCurrencySuccess) name:CHANGE_LOCAL_CURRENCY_SUCCESS_NOTIFICATION_KEY object:nil];
    
    [self changeCurrencySymbol:currencyCode];
}

@end

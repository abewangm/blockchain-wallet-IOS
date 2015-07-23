//
//  SettingsBitcoinUnitTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/22/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SettingsBitcoinUnitTableViewController.h"
#import "AppDelegate.h"

@interface SettingsBitcoinUnitTableViewController ()
@property (nonatomic, copy) NSArray *keysArray;
@property (nonatomic) CurrencySymbol *currentCurrencySymbol;
@property (nonatomic) NSString *selectedCurrencyCode;
@end

@implementation SettingsBitcoinUnitTableViewController

- (void)alertViewForErrorLoadingSettings
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_SETTINGS_ERROR_LOADING_TITLE message:BC_STRING_SETTINGS_ERROR_LOADING_MESSAGE delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
    [alertView show];
}

- (CurrencySymbol *)getBtcSymbolFromLatestResponse
{
    return app.latestResponse.symbol_btc;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [[NSNotificationCenter defaultCenter] addObserver:self.delegate selector:@selector(changeLocalCurrencySuccess) name:NOTIFICATION_KEY_CHANGE_LOCAL_CURRENCY_SUCCESS object:nil];
    [self changeCurrencySymbol:self.selectedCurrencyCode];
}

- (void)changeCurrencySymbol:(NSString *)code
{
    [app.wallet changeBtcCurrency:code];
}

- (void)setItemsDictionary:(NSDictionary *)itemsDictionary
{
    _itemsDictionary = itemsDictionary;
    self.keysArray = [[_itemsDictionary allKeys] sortedArrayUsingSelector:@selector(compare:)];
    self.currentCurrencySymbol = [self getBtcSymbolFromLatestResponse];
    
    // Currency preference is not set until returning from settings and updating the wallet, so store temporarily in NSUserDefaults for display purposes
    
    NSString *loadedCurrencySymbol = [[NSUserDefaults standardUserDefaults] valueForKey:@"btcUnit"] == nil ? [self getBtcSymbolFromLatestResponse].name : [[NSUserDefaults standardUserDefaults] valueForKey:@"btcUnit"];
    
    NSArray *temporaryArray = [self.itemsDictionary allKeysForObject:loadedCurrencySymbol];
    NSString *preferredCurrencySymbol = [temporaryArray firstObject];
    
    if (preferredCurrencySymbol == nil) {
        [self alertViewForErrorLoadingSettings];
    } else {
        self.selectedCurrencyCode = preferredCurrencySymbol;
    }
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
    cell.detailTextLabel.text = [[NSString alloc] initWithFormat:@"%@", currencyCode];
    cell.textLabel.text = self.itemsDictionary[currencyCode];
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *currencyCode = self.keysArray[indexPath.row];
    
    self.selectedCurrencyCode = currencyCode;
    
    [[NSUserDefaults standardUserDefaults] setValue:self.itemsDictionary[currencyCode] forKey:@"btcUnit"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self.tableView reloadData];
}


@end

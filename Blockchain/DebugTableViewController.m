//
//  DebugTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/29/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//

#import "DebugTableViewController.h"
#import "Blockchain-Swift.h"
#import "AppDelegate.h"

@interface DebugTableViewController ()

@end

@implementation DebugTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:BC_STRING_DONE style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
    self.navigationItem.title = BC_STRING_DEBUG;
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)alertToChangeURLName:(NSString *)name userDefaultKey:(NSString *)key currentURL:(NSString *)currentURL
{
    UIAlertController *changeURLAlert = [UIAlertController alertControllerWithTitle:name message:nil preferredStyle:UIAlertControllerStyleAlert];
    [changeURLAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.text = currentURL;
        secureTextField.returnKeyType = UIReturnKeyDone;
    }];
    [changeURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)[[changeURLAlert textFields] firstObject];
        [[NSUserDefaults standardUserDefaults] setObject:secureTextField.text forKey:key];
        [self.tableView reloadData];
    }]];
    [changeURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_RESET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:key];
        [self.tableView reloadData];
    }]];
    [changeURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:changeURLAlert animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 3;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = BC_STRING_SERVER_URL;
            cell.detailTextLabel.text =  [app serverURL];
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            break;
        }
        case 1: {
            cell.textLabel.text = BC_STRING_WEBSOCKET_URL;
            cell.detailTextLabel.text = [app webSocketURL];
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            break;
        }
        case 2: {
            cell.textLabel.text = BC_STRING_NEARBY_MERCHANTS_URL;
            cell.detailTextLabel.text = [app nearbyMerchantsURL];
            cell.detailTextLabel.adjustsFontSizeToFitWidth = YES;
            break;
        }
        default:
            break;
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:NO];
    switch (indexPath.row) {
        case 0:
            [self alertToChangeURLName:BC_STRING_SERVER_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL currentURL:[app serverURL]];
            break;
        case 1:
            [self alertToChangeURLName:BC_STRING_WEBSOCKET_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL currentURL:[app webSocketURL]];
            break;
        case 2:
            [self alertToChangeURLName:BC_STRING_NEARBY_MERCHANTS_URL userDefaultKey:USER_DEFAULTS_KEY_DEBUG_NEARBY_MERCHANTS_URL currentURL:[app nearbyMerchantsURL]];
            break;
        default:
            break;
    }
}


@end

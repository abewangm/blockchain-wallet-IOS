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

- (void)alertToChangeServerURL
{
    UIAlertController *changeServerURLAlert = [UIAlertController alertControllerWithTitle:BC_STRING_SERVER_URL message:nil preferredStyle:UIAlertControllerStyleAlert];
    [changeServerURLAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.text = [app serverURL];
        secureTextField.returnKeyType = UIReturnKeyDone;
    }];
    [changeServerURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = [[changeServerURLAlert textFields] firstObject];
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL];
        [self.tableView reloadData];
    }]];
    [changeServerURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_RESET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL];
        [self.tableView reloadData];
    }]];
    [changeServerURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:changeServerURLAlert animated:YES completion:nil];
}

- (void)alertToChangeWebSocketURL
{
    UIAlertController *changeWebSocketURLAlert = [UIAlertController alertControllerWithTitle:BC_STRING_WEBSOCKET_URL message:nil preferredStyle:UIAlertControllerStyleAlert];
    [changeWebSocketURLAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.text = [app webSocketURL];
        secureTextField.returnKeyType = UIReturnKeyDone;
    }];
    [changeWebSocketURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = [[changeWebSocketURLAlert textFields] firstObject];
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL];
        [self.tableView reloadData];
    }]];
    [changeWebSocketURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_RESET style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL];
        [self.tableView reloadData];
    }]];
    [changeWebSocketURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:changeWebSocketURLAlert animated:YES completion:nil];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 2;
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
            [self alertToChangeServerURL];
            break;
        default:
            [self alertToChangeWebSocketURL];
            break;
    }
}


@end

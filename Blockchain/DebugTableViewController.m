//
//  DebugTableViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 12/29/15.
//  Copyright © 2015 Qkos Services Ltd. All rights reserved.
//

#import "DebugTableViewController.h"
#import "Blockchain-Swift.h"

@interface DebugTableViewController ()

@end

@implementation DebugTableViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:BC_STRING_DONE style:UIBarButtonItemStyleDone target:self action:@selector(dismiss)];
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)changeServerURL
{
    UIAlertController *changeServerURLAlert = [UIAlertController alertControllerWithTitle:BC_STRING_SERVER_URL message:nil preferredStyle:UIAlertControllerStyleAlert];
    [changeServerURLAlert addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        BCSecureTextField *secureTextField = (BCSecureTextField *)textField;
        secureTextField.text = [self serverURL];
        secureTextField.returnKeyType = UIReturnKeyDone;
    }];
    [changeServerURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        UITextField *textField = [[changeServerURLAlert textFields] firstObject];
        [[NSUserDefaults standardUserDefaults] setObject:textField.text forKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL];
        [self.tableView reloadData];
    }]];
    [changeServerURLAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:changeServerURLAlert animated:YES completion:nil];
}

- (NSString *)serverURL
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL] == nil ? WebROOT : [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
    
    switch (indexPath.row) {
        case 0: {
            cell.textLabel.text = BC_STRING_SERVER_URL;
            cell.detailTextLabel.text =  [self serverURL];
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
            [self changeServerURL];
            break;
        default:
            break;
    }
}


@end

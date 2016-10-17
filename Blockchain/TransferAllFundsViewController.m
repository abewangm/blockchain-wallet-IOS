//
//  TransferAllFundsViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 10/12/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransferAllFundsViewController.h"
#import "TransferAllFundsBuilder.h"
#import "TransferAmountTableCell.h"
#import "BCAddressSelectionView.h"
#import "BCModalViewController.h"

@interface TransferAllFundsViewController () <TransferAllFundsDelegate, UITableViewDataSource, UITableViewDelegate, AddressSelectionDelegate>
@property (nonatomic) uint64_t amount;
@property (nonatomic) uint64_t fee;
@property (nonatomic) NSArray *addressesUsed;
@property (nonatomic) NSString *temporarySecondPassword;
@property (nonatomic) TransferAllFundsBuilder *transferPaymentBuilder;
@property (nonatomic) int selectedAccountIndex;

@property (nonatomic) UITableView *tableView;
@property (nonatomic) UIButton *sendButton;
@property (nonatomic) UILabel *fromLabel;
@property (nonatomic) UILabel *toLabel;
@property (nonatomic) UILabel *amountLabel;
@end

@implementation TransferAllFundsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    [self setupViews];
    self.transferPaymentBuilder = [[TransferAllFundsBuilder alloc] initUsingSendScreen:NO];
    self.transferPaymentBuilder.delegate = self;
}

- (void)setupViews
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT + 182)];
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    [self.view addSubview:self.tableView];
    self.tableView.scrollEnabled = NO;
    
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.center.x - 120, self.tableView.frame.origin.y + self.tableView.frame.size.height + 24, 240, 40)];
    self.sendButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    self.sendButton.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.sendButton setTitle:BC_STRING_TRANSFER_FUNDS forState:UIControlStateNormal];
    [self.sendButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.enabled = NO;
    self.sendButton.clipsToBounds = YES;
    self.sendButton.layer.cornerRadius = 16;
    [self.view addSubview:self.sendButton];
}

- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed;
{
    self.amount = [amount longLongValue];
    self.fee = [fee longLongValue];
    self.addressesUsed = addressesUsed;
    
    [self.tableView reloadData];
    
    [self.transferPaymentBuilder setupFirstTransferWithAddressesUsed:addressesUsed];
}

- (void)showSummaryForTransferAll
{
    self.sendButton.enabled = YES;
}

- (void)send
{
    [self.transferPaymentBuilder transferAllFundsToAccountWithSecondPassword:nil];
}

- (void)sendDuringTransferAll:(NSString *)secondPassword
{
    [self.transferPaymentBuilder transferAllFundsToAccountWithSecondPassword:secondPassword];
}

- (void)didFinishTransferFunds:(NSString *)summary
{
    
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return 4;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 0) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        cell.textLabel.text = BC_STRING_FROM;
        cell.detailTextLabel.text = self.addressesUsed == nil ? @"" : [NSString stringWithFormat:BC_STRING_ARGUMENT_ADDRESSES, [self.addressesUsed count]];
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    } else if (indexPath.row == 1) {
        UITableViewCell *cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:nil];
        cell.textLabel.text = BC_STRING_TO;
        cell.detailTextLabel.text = [self.transferPaymentBuilder getLabelForDestinationAccount];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return cell;
    } else if (indexPath.row == 2) {
        TransferAmountTableCell *cell = [[TransferAmountTableCell alloc] init];
        cell.mainLabel.text = BC_STRING_TRANSFER_AMOUNT;
        cell.fiatLabel.text = [self.transferPaymentBuilder formatMoney:self.amount localCurrency:YES];
        cell.btcLabel.text = [self.transferPaymentBuilder formatMoney:self.amount localCurrency:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    } else {
        TransferAmountTableCell *cell = [[TransferAmountTableCell alloc] init];
        cell.mainLabel.text = BC_STRING_FEE;
        cell.fiatLabel.text = [self.transferPaymentBuilder formatMoney:self.fee localCurrency:YES];
        cell.btcLabel.text = [self.transferPaymentBuilder formatMoney:self.fee localCurrency:NO];
        cell.accessoryType = UITableViewCellAccessoryNone;
        return cell;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.row == 2) {
        [cell setSeparatorInset:UIEdgeInsetsMake(0, 15, 0, CGRectGetWidth(cell.bounds)-15)];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    if (indexPath.row == 1) {
        BCAddressSelectionView *selectorView = [[BCAddressSelectionView alloc] initWithWallet:[self.transferPaymentBuilder wallet] showOwnAddresses:YES allSelectable:YES accountsOnly:YES];
        selectorView.delegate = self;
        selectorView.frame = CGRectMake(0, DEFAULT_HEADER_HEIGHT, self.view.frame.size.width, self.view.frame.size.height);
        
        UIViewController *viewController = [UIViewController new];
        viewController.automaticallyAdjustsScrollViewInsets = NO;
        [viewController.view addSubview:selectorView];
    
        [self.navigationController pushViewController:viewController animated:YES];
    }
}

- (void)didSelectFromAccount:(int)account
{
    [self.navigationController popViewControllerAnimated:YES];
    [self.transferPaymentBuilder setupTransfersToAccount:account];
    [self.tableView reloadRowsAtIndexPaths:@[[NSIndexPath indexPathForRow:1 inSection:0]] withRowAnimation:UITableViewRowAnimationNone];
}

- (void)didSelectToAccount:(int)account
{
    DLog(@"Error: Selected To Account!");
}

- (void)didSelectToAddress:(NSString *)address
{
    DLog(@"Error: Selected To Address!");
}

- (void)didSelectFromAddress:(NSString *)address
{
    DLog(@"Error: Selected From Address!");
    
}

@end

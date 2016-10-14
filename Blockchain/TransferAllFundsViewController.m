//
//  TransferAllFundsViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 10/12/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransferAllFundsViewController.h"
#import "TransferAllFundsBuilder.h"

@interface TransferAllFundsViewController () <TransferAllFundsDelegate>
@property (nonatomic) uint64_t amount;
@property (nonatomic) uint64_t fee;
@property (nonatomic) NSArray *addressesUsed;
@property (nonatomic) NSString *temporarySecondPassword;
@property (nonatomic) TransferAllFundsBuilder *transferPaymentBuilder;
@property (nonatomic) int selectedAccountIndex;

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
    self.fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, DEFAULT_HEADER_HEIGHT + 16, 200, 22)];
    [self.view addSubview:self.fromLabel];
    
    self.toLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, DEFAULT_HEADER_HEIGHT + 46, 200, 22)];
    [self.view addSubview:self.toLabel];
    
    self.amountLabel = [[UILabel alloc] initWithFrame:CGRectMake(16, DEFAULT_HEADER_HEIGHT + 76, 200, 22)];
    [self.view addSubview:self.amountLabel];
    
    self.sendButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
    [self.sendButton setTitle:BC_STRING_SEND forState:UIControlStateNormal];
    [self.sendButton setTitleColor:COLOR_BUTTON_BLUE forState:UIControlStateNormal];
    [self.sendButton addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
    self.sendButton.center = self.view.center;
    self.sendButton.enabled = NO;
    [self.view addSubview:self.sendButton];
}

- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed;
{
    self.amount = [amount longLongValue];
    self.fee = [fee longLongValue];
    self.addressesUsed = addressesUsed;
    
    self.fromLabel.text = [NSString stringWithFormat:BC_STRING_ARGUMENT_ADDRESSES, [addressesUsed count]];
    self.toLabel.text = [self.transferPaymentBuilder getLabelForDestinationAccount];
    self.amountLabel.text = [self.transferPaymentBuilder getLabelForAmount:self.amount];
    
    [self.transferPaymentBuilder setupFirstTransferWithAddressesUsed:addressesUsed];
}

- (void)showSummaryForTransferAll
{
    // Display amount, fee, addresses used, etc.
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

@end

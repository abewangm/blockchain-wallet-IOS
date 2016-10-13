//
//  TransferAllFundsViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 10/12/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransferAllFundsViewController.h"
#import "RootService.h"

@interface TransferAllFundsViewController ()
@property (nonatomic) uint64_t amount;
@property (nonatomic) uint64_t fee;
@property (nonatomic) NSArray *addressesUsed;
@end

@implementation TransferAllFundsViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupViews];
    [self transferAllFunds];
}

- (void)setupViews
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 100, 200)];
    [button setTitle:BC_STRING_SEND forState:UIControlStateNormal];
    [button setTitleColor:COLOR_BUTTON_BLUE forState:UIControlStateNormal];
    [button addTarget:self action:@selector(send) forControlEvents:UIControlEventTouchUpInside];
    button.center = self.view.center;
    [self.view addSubview:button];
}

- (void)transferAllFunds
{
    [app.wallet getInfoForTransferAllFundsToDefaultAccount];
}

- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed;
{
    self.amount = [amount longLongValue];
    self.fee = [fee longLongValue];
    self.addressesUsed = addressesUsed;
}

- (void)send
{

}

@end

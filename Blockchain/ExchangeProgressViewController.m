//
//  ExchangeProgressViewController.m
//  Blockchain
//
//  Created by Maurice A. on 11/20/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeProgressViewController.h"
#import "ExchangeDetailView.h"

#define DETAIL_VIEW_HEIGHT 283

@interface ExchangeProgressViewController ()

@end

@implementation ExchangeProgressViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    ExchangeDetailView *detailView = [[ExchangeDetailView alloc] initWithFrame:CGRectMake(0, 0, WINDOW_WIDTH, DETAIL_VIEW_HEIGHT)];
    [detailView createPseudoTableWithDepositAmount:@"" receiveAmount:@"" exchangeRate:@"" transactionFee:@"" networkTransactionFee:@""];
    [self.view addSubview:detailView];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

@end

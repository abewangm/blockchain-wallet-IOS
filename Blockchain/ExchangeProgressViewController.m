//
//  ExchangeProgressViewController.m
//  Blockchain
//
//  Created by Maurice A. on 11/20/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeProgressViewController.h"
#import "ExchangeDetailView.h"

@interface ExchangeProgressViewController ()

@end

@implementation ExchangeProgressViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    ExchangeDetailView *detailView = [[ExchangeDetailView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, WINDOW_WIDTH, 0) fetchedTrade:self.trade];
    [self.view addSubview:detailView];
}

@end

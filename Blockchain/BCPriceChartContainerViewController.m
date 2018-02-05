//
//  BCPriceChartContainerViewController.m
//  Blockchain
//
//  Created by kevinwu on 2/5/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCPriceChartContainerViewController.h"

@interface BCPriceChartContainerViewController ()

@end

@implementation BCPriceChartContainerViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor blackColor];
    self.view.alpha = BUSY_VIEW_LABEL_ALPHA;
    
    CGFloat buttonWidth = 50;
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 8 - buttonWidth, 30, buttonWidth, buttonWidth)];
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [closeButton addTarget:self action:@selector(closeButtonTapped) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:closeButton];
}

- (void)closeButtonTapped
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

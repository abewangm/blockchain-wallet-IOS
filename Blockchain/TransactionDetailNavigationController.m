//
//  TransactionDetailNavigationController.m
//  Blockchain
//
//  Created by Kevin Wu on 9/2/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransactionDetailNavigationController.h"

@implementation TransactionDetailNavigationController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UIView *topBar = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT)];
    topBar.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBar];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 17.5, self.view.frame.size.width - 160, 40)];
    headerLabel.font = [UIFont systemFontOfSize:22.0];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    headerLabel.text = BC_STRING_TRANSACTION;
    [topBar addSubview:headerLabel];
    
    UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
    backButton.frame = CGRectMake(self.view.frame.size.width - 80, 15, 80, 51);
    backButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    backButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    [backButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
    [backButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
    [backButton setTitleColor:[UIColor colorWithWhite:0.56 alpha:1.0] forState:UIControlStateHighlighted];
    [backButton addTarget:self action:@selector(dismiss) forControlEvents:UIControlEventTouchUpInside];
    [topBar addSubview:backButton];
    
    [self setupBusyView];
}

- (void)setupBusyView
{
    BCFadeView *busyView = [[BCFadeView alloc] initWithFrame:self.view.frame];
    busyView.backgroundColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.5];
    UIView *textWithSpinnerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 250, 110)];
    textWithSpinnerView.backgroundColor = [UIColor whiteColor];
    [busyView addSubview:textWithSpinnerView];
    textWithSpinnerView.center = busyView.center;
    
    UILabel *busyLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, BUSY_VIEW_LABEL_WIDTH, BUSY_VIEW_LABEL_HEIGHT)];
    busyLabel.adjustsFontSizeToFitWidth = YES;
    busyLabel.font = [UIFont systemFontOfSize:BUSY_VIEW_LABEL_FONT_SYSTEM_SIZE];
    busyLabel.alpha = BUSY_VIEW_LABEL_ALPHA;
    busyLabel.textAlignment = NSTextAlignmentCenter;
    busyLabel.text = BC_STRING_LOADING_SYNCING_WALLET;
    busyLabel.center = CGPointMake(textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 + 15);
    [textWithSpinnerView addSubview:busyLabel];
    
    UIActivityIndicatorView *spinner = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
    spinner.center = CGPointMake(textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 - 15);
    [textWithSpinnerView addSubview:spinner];
    [textWithSpinnerView bringSubviewToFront:spinner];
    [spinner startAnimating];
    
    busyView.containerView = textWithSpinnerView;
    [busyView fadeOut];
    
    [self.view addSubview:busyView];
    
    [self.view bringSubviewToFront:busyView];
    
    self.busyView = busyView;
}

- (void)dismiss
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end

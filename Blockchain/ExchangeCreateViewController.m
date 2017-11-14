//
//  ExchangeCreateViewController.m
//  Blockchain
//
//  Created by kevinwu on 10/23/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeCreateViewController.h"
#import "FromToView.h"
#import "Blockchain-Swift.h"

#define COLOR_EXCHANGE_BACKGROUND_GRAY UIColorFromRGB(0xf5f6f8)

@interface ExchangeCreateViewController ()
@property (nonatomic) id to;
@end

@implementation ExchangeCreateViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = COLOR_EXCHANGE_BACKGROUND_GRAY;
    
    CGFloat windowWidth = WINDOW_WIDTH;
    FromToView *fromToView = [[FromToView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT + 16, windowWidth, 96) enableToTextField:NO];
    [self.view addSubview:fromToView];
    
    UIView *amountView = [[UIView alloc] initWithFrame:CGRectMake(0, fromToView.frame.origin.y + fromToView.frame.size.height + 1, windowWidth, 100)];
    amountView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:amountView];
    
    UILabel *leftLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 40, 30)];
    leftLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    leftLabel.textColor = COLOR_TEXT_DARK_GRAY;
    leftLabel.text = CURRENCY_SYMBOL_BTC;
    [amountView addSubview:leftLabel];
    
    UIButton *assetToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 12, 30, 30)];
    assetToggleButton.center = CGPointMake(windowWidth/2, assetToggleButton.center.y);
    [amountView addSubview:assetToggleButton];
    
    UILabel *rightLabel = [[UILabel alloc] initWithFrame:CGRectMake(assetToggleButton.frame.origin.x + assetToggleButton.frame.size.width + 15, 12, 40, 30)];
    rightLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    rightLabel.textColor = COLOR_TEXT_DARK_GRAY;
    rightLabel.text = CURRENCY_SYMBOL_ETH;
    [amountView addSubview:rightLabel];
    
    CGFloat leftFieldOriginX = leftLabel.frame.origin.x + leftLabel.frame.size.width + 8;
    BCSecureTextField *leftField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(leftFieldOriginX, 12, assetToggleButton.frame.origin.x - 8 - leftFieldOriginX, 30)];
    [amountView addSubview:leftField];
    
    CGFloat rightFieldOriginX = rightLabel.frame.origin.x + rightLabel.frame.size.width + 8;
    BCSecureTextField *rightField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(rightFieldOriginX, 12, windowWidth - 8 - rightFieldOriginX, 30)];
    [amountView addSubview:rightField];
}

@end

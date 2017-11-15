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
@property (nonatomic) UILabel *leftBottomLabel;
@property (nonatomic) UILabel *rightBottomLabel;
@property (nonatomic) BCSecureTextField *leftField;
@property (nonatomic) BCSecureTextField *rightField;
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
    
    UILabel *leftTopLabel = [[UILabel alloc] initWithFrame:CGRectMake(15, 12, 40, 30)];
    leftTopLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    leftTopLabel.textColor = COLOR_TEXT_DARK_GRAY;
    leftTopLabel.text = CURRENCY_SYMBOL_BTC;
    [amountView addSubview:leftTopLabel];
    
    UIButton *assetToggleButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 12, 30, 30)];
    assetToggleButton.center = CGPointMake(windowWidth/2, assetToggleButton.center.y);
    [amountView addSubview:assetToggleButton];
    
    UILabel *rightTopLabel = [[UILabel alloc] initWithFrame:CGRectMake(assetToggleButton.frame.origin.x + assetToggleButton.frame.size.width + 15, 12, 40, 30)];
    rightTopLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    rightTopLabel.textColor = COLOR_TEXT_DARK_GRAY;
    rightTopLabel.text = CURRENCY_SYMBOL_ETH;
    [amountView addSubview:rightTopLabel];
    
    CGFloat leftFieldOriginX = leftTopLabel.frame.origin.x + leftTopLabel.frame.size.width + 8;
    BCSecureTextField *leftField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(leftFieldOriginX, 12, assetToggleButton.frame.origin.x - 8 - leftFieldOriginX, 30)];
    leftField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    leftField.textColor = COLOR_TEXT_DARK_GRAY;
    [amountView addSubview:leftField];
    self.leftField = leftField;
    
    CGFloat rightFieldOriginX = rightTopLabel.frame.origin.x + rightTopLabel.frame.size.width + 8;
    BCSecureTextField *rightField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(rightFieldOriginX, 12, windowWidth - 8 - rightFieldOriginX, 30)];
    rightField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    rightField.textColor = COLOR_TEXT_DARK_GRAY;
    [amountView addSubview:rightField];
    self.rightField = rightField;
    
    UIView *dividerLine = [[UIView alloc] initWithFrame:CGRectMake(leftFieldOriginX, leftField.frame.origin.y + leftField.frame.size.height + 12, windowWidth - leftFieldOriginX, 0.5)];
    dividerLine.backgroundColor = COLOR_LINE_GRAY;
    [amountView addSubview:dividerLine];
    
    UILabel *leftBottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(leftFieldOriginX, dividerLine.frame.origin.y + dividerLine.frame.size.height + 12, leftField.frame.size.width, 30)];
    leftBottomLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    leftBottomLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [amountView addSubview:leftBottomLabel];
    leftBottomLabel.text = @"LeftBottomLabelText";
    self.leftBottomLabel = leftBottomLabel;
    
    UILabel *rightBottomLabel = [[UILabel alloc] initWithFrame:CGRectMake(rightFieldOriginX, dividerLine.frame.origin.y + dividerLine.frame.size.height + 12, rightField.frame.size.width, 30)];
    rightBottomLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    rightBottomLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [amountView addSubview:rightBottomLabel];
    rightBottomLabel.text = @"RightBottomLabelText";
    self.rightBottomLabel = rightBottomLabel;
}



@end

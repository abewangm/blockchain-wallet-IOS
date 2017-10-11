//
//  ExchangeOverviewViewController.m
//  Blockchain
//
//  Created by kevinwu on 10/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeOverviewViewController.h"
#import "BCLine.h"

@interface ExchangeOverviewViewController ()

@end

@implementation ExchangeOverviewViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;

    CGFloat windowWidth = WINDOW_WIDTH;
    UIView *newExchangeView = [[UIView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT + 30, windowWidth, 70)];
    newExchangeView.backgroundColor = [UIColor whiteColor];
    
    BCLine *topLine = [[BCLine alloc] initWithYPosition:newExchangeView.frame.origin.y - 1];
    [self.view addSubview:topLine];
    
    BCLine *bottomLine = [[BCLine alloc] initWithYPosition:newExchangeView.frame.origin.y + newExchangeView.frame.size.height];
    [self.view addSubview:bottomLine];
    
    CGFloat exchangeLabelOriginX = 80;
    CGFloat chevronWidth = 15;
    CGFloat exchangeLabelHeight = 30;
    UILabel *newExchangeLabel = [[UILabel alloc] initWithFrame:CGRectMake(exchangeLabelOriginX, newExchangeView.frame.size.height/2 - exchangeLabelHeight/2, windowWidth - exchangeLabelOriginX - chevronWidth, exchangeLabelHeight)];
    newExchangeLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_MEDIUM];
    newExchangeLabel.text = @"New Exchange";
    newExchangeLabel.textColor = COLOR_TEXT_DARK_GRAY;
    [newExchangeView addSubview:newExchangeLabel];
    
    CGFloat exchangeIconImageViewWidth = 50;
    UIImageView *exchangeIconImageView = [[UIImageView alloc] initWithFrame:CGRectMake(16, newExchangeView.frame.size.height/2 - exchangeIconImageViewWidth/2, exchangeIconImageViewWidth, exchangeIconImageViewWidth)];
    exchangeIconImageView.backgroundColor = [UIColor greenColor];
    [newExchangeView addSubview:exchangeIconImageView];
    
    UIImageView *chevronImageView = [[UIImageView alloc] initWithFrame:CGRectMake(newExchangeView.frame.size.width - 8 - chevronWidth, newExchangeView.frame.size.height/2 - chevronWidth/2, chevronWidth, chevronWidth)];
    chevronImageView.image = [UIImage imageNamed:@"chevron_right"];
    chevronImageView.contentMode = UIViewContentModeScaleAspectFit;
    chevronImageView.tintColor = COLOR_TABLE_VIEW_BACKGROUND_LIGHT_GRAY;
    [newExchangeView addSubview:chevronImageView];
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(newExchangeClicked)];
    [newExchangeView addGestureRecognizer:tapGesture];
    
    [self.view addSubview:newExchangeView];
}

- (void)newExchangeClicked
{
    
}

@end

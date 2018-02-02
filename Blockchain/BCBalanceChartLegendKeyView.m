//
//  BCBalanceChartLegendKeyView.m
//  Blockchain
//
//  Created by kevinwu on 2/2/18.
//  Copyright © 2018 Blockchain Luxembourg S.A. All rights reserved.
//

#import "BCBalanceChartLegendKeyView.h"

@implementation BCBalanceChartLegendKeyView

- (id)initWithFrame:(CGRect)frame assetColor:(UIColor *)color assetName:(NSString *)name balance:(NSString *)balance fiatBalance:(NSString *)fiatBalance
{
    if (self == [super initWithFrame:frame]) {
        
        CGFloat lineHeight = 3;
        
        UIView *colorView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, lineHeight)];
        colorView.backgroundColor = color;
        [self addSubview:colorView];
        
        CGFloat labelHeight = frame.size.height/3 - lineHeight/3;
        UIColor *labelTextColor = COLOR_TEXT_DARK_GRAY;
        
        UILabel *assetLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, colorView.frame.origin.y + colorView.frame.size.height, frame.size.width, labelHeight)];
        assetLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_SMALL];
        assetLabel.text = name;
        assetLabel.textColor = labelTextColor;
        [self addSubview:assetLabel];

        UILabel *balanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, assetLabel.frame.origin.y + assetLabel.frame.size.height, frame.size.width, labelHeight)];
        balanceLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
        balanceLabel.text = balance;
        balanceLabel.textColor = labelTextColor;
        [self addSubview:balanceLabel];

        UILabel *fiatBalanceLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, balanceLabel.frame.origin.y + balanceLabel.frame.size.height, frame.size.width, labelHeight)];
        fiatBalanceLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_SMALL];
        fiatBalanceLabel.text = fiatBalance;
        fiatBalanceLabel.textColor = labelTextColor;
        [self addSubview:fiatBalanceLabel];
    }
    
    return self;
}

@end

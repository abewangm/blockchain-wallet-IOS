//
//  ExchangeConfirmViewController.m
//  Blockchain
//
//  Created by kevinwu on 10/31/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ExchangeConfirmViewController.h"
#import "BCLine.h"
#import "UILabel+CGRectForSubstring.h"

#define MARGIN_HORIZONTAL 20

@interface ExchangeConfirmViewController ()
@property (nonatomic) CGFloat bottomLineYPosition;
@end

@implementation ExchangeConfirmViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    [self setupRows];
    
    [self setupAgreementViews];
}

- (void)setupRows
{
    UIView *rowDeposit = [self rowViewWithText:[NSString stringWithFormat:BC_STRING_ARGUMENT_TO_DEPOSIT, @""] accessoryText:@"btc" yPosition:DEFAULT_HEADER_HEIGHT];
    [self.view addSubview:rowDeposit];
    
    UIView *rowReceive = [self rowViewWithText:[NSString stringWithFormat:BC_STRING_ARGUMENT_TO_BE_RECEIVED, @""] accessoryText:@"eth" yPosition:rowDeposit.frame.origin.y + rowDeposit.frame.size.height];
    [self.view addSubview:rowReceive];
    
    UIView *rowExchangeRate = [self rowViewWithText:BC_STRING_EXCHANGE_RATE accessoryText:@"exr" yPosition:rowReceive.frame.origin.y + rowReceive.frame.size.height];
    [self.view addSubview:rowExchangeRate];
    
    UIView *rowTransactionFee = [self rowViewWithText:BC_STRING_TRANSACTION_FEE accessoryText:@"txfee" yPosition:rowExchangeRate.frame.origin.y + rowExchangeRate.frame.size.height];
    [self.view addSubview:rowTransactionFee];
    
    UIView *rowWithdrawalFee = [self rowViewWithText:BC_STRING_SHAPESHIFT_WITHDRAWAL_FEE accessoryText:@"wfee" yPosition:rowTransactionFee.frame.origin.y + rowTransactionFee.frame.size.height];
    [self.view addSubview:rowWithdrawalFee];
    
    self.bottomLineYPosition = rowWithdrawalFee.frame.origin.y + rowWithdrawalFee.frame.size.height;
    
    BCLine *bottomLine = [[BCLine alloc] initWithYPosition:self.bottomLineYPosition];
    [self.view addSubview:bottomLine];
}

- (UIView *)rowViewWithText:(NSString *)text accessoryText:(NSString *)accessoryText yPosition:(CGFloat)yPosition
{
    CGFloat horizontalMargin = MARGIN_HORIZONTAL;
    CGFloat rowWidth = WINDOW_WIDTH;
    CGFloat rowHeight = 60;
    UIView *rowView = [[UIView alloc] initWithFrame:CGRectMake(0, yPosition, rowWidth, rowHeight)];
    
    UILabel *mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(horizontalMargin, 0, rowWidth/2, rowHeight)];
    mainLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
    mainLabel.text = text;
    [rowView addSubview:mainLabel];
    
    UILabel *accessoryLabel = [[UILabel alloc] initWithFrame:CGRectMake(rowWidth/2, 0, rowWidth/2 - horizontalMargin, rowHeight)];
    accessoryLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
    accessoryLabel.text = accessoryText;
    accessoryLabel.textAlignment = NSTextAlignmentRight;
    accessoryLabel.numberOfLines = 0;
    [rowView addSubview:accessoryLabel];
    
    BCLine *topLine = [[BCLine alloc] initWithYPosition:yPosition];
    [self.view addSubview:topLine];
    
    return rowView;
}

- (void)setupAgreementViews
{
    CGFloat horizontalMargin = MARGIN_HORIZONTAL;
    CGFloat windowWidth = WINDOW_WIDTH;
    
    UISwitch *agreementSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(horizontalMargin, self.bottomLineYPosition + 16, 0, 0)];
    agreementSwitch.onTintColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    [self.view addSubview:agreementSwitch];
    
    CGFloat agreementLabelOriginX = agreementSwitch.frame.origin.x + agreementSwitch.frame.size.width + 8;
    UILabel *agreementLabel = [[UILabel alloc] initWithFrame:CGRectMake(agreementLabelOriginX, 0, windowWidth - horizontalMargin - agreementLabelOriginX, 30)];
    agreementLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_EXTRA_EXTRA_EXTRA_SMALL];
    agreementLabel.center = CGPointMake(agreementLabel.center.x, agreementSwitch.center.y);
    
    NSAttributedString *attributedStringPrefix = [[NSAttributedString alloc] initWithString:BC_STRING_AGREE_TO_SHAPESHIFT];
    NSMutableAttributedString *termsAndConditionsText = [[NSMutableAttributedString alloc] initWithAttributedString:attributedStringPrefix];
    [termsAndConditionsText addAttribute:NSForegroundColorAttributeName value:COLOR_TEXT_DARK_GRAY range:NSMakeRange(0, [attributedStringPrefix length])];
    
    NSAttributedString *attributedStringSpace = [[NSAttributedString alloc] initWithString:@" "];
    
    NSAttributedString *attributedStringSuffix = [[NSAttributedString alloc] initWithString:BC_STRING_TERMS_AND_CONDITIONS];
    NSMutableAttributedString *termsAndConditionsSuffix = [[NSMutableAttributedString alloc] initWithAttributedString:attributedStringSuffix];
    [termsAndConditionsSuffix addAttribute:NSForegroundColorAttributeName value:COLOR_BLOCKCHAIN_LIGHT_BLUE range:NSMakeRange(0, [attributedStringSuffix length])];
    
    [termsAndConditionsText appendAttributedString:attributedStringSpace];
    [termsAndConditionsText appendAttributedString:termsAndConditionsSuffix];
    
    [agreementLabel setAttributedText:termsAndConditionsText];
    
    NSString *originalString = [[NSString alloc] initWithFormat:@"%@%@%@", BC_STRING_AGREE_TO_SHAPESHIFT, @" ", BC_STRING_TERMS_AND_CONDITIONS];
    UILabel *measuringLabel = [[UILabel alloc] initWithFrame:agreementLabel.bounds];
    measuringLabel.font = agreementLabel.font;
    measuringLabel.text = originalString;
    
    CGRect tappableArea = [measuringLabel boundingRectForCharacterRange:[originalString rangeOfString:BC_STRING_TERMS_AND_CONDITIONS]];
    UIView *tappableView = [[UIView alloc] initWithFrame:tappableArea];
    tappableView.userInteractionEnabled = YES;
    agreementLabel.userInteractionEnabled = YES;
    [tappableView addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self
                                             action:@selector(handleTapView)]];
    [agreementLabel addSubview:tappableView];
    [self.view addSubview:agreementLabel];
}

- (void)handleTapView
{
    DLog(@"Terms and conditions tapped");
}

@end

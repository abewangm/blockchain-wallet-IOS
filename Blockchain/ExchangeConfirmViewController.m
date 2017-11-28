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
    
    // TODO: Instantiate ExchangeDetailView object and add as sub view
    
    [self setupAgreementViews];
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

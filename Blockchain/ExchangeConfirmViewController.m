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
#import "ExchangeDetailView.h"
#import "RootService.h"
#import "BCNavigationController.h"

#define MARGIN_HORIZONTAL 20

@interface ExchangeConfirmViewController ()
@property (nonatomic) ExchangeTrade *trade;
@property (nonatomic) UIButton *confirmButton;
@property (nonatomic) UISwitch *agreementSwitch;
@end

@implementation ExchangeConfirmViewController

- (id)initWithExchangeTrade:(ExchangeTrade *)trade
{
    if (self == [super init]) {
        self.trade = trade;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat windowWidth = WINDOW_WIDTH;
    ExchangeDetailView *detailView = [[ExchangeDetailView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, windowWidth, 0) trade:self.trade];
    [self.view addSubview:detailView];
    
    [self setupAgreementViewsAtYPosition:detailView.frame.origin.y + detailView.frame.size.height + 16];
    
    [self setupConfirmButton];
}

- (void)setupAgreementViewsAtYPosition:(CGFloat)yPosition
{
    CGFloat horizontalMargin = MARGIN_HORIZONTAL;
    CGFloat windowWidth = WINDOW_WIDTH;
    
    UISwitch *agreementSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(horizontalMargin, yPosition, 0, 0)];
    agreementSwitch.onTintColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    [self.view addSubview:agreementSwitch];
    [agreementSwitch addTarget:self action:@selector(agreementSwitchChanged:) forControlEvents:UIControlEventValueChanged];
    self.agreementSwitch = agreementSwitch;

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

- (void)setupConfirmButton
{
    UIButton *button = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, WINDOW_WIDTH - 32, BUTTON_HEIGHT)];
    button.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    button.layer.cornerRadius = CORNER_RADIUS_BUTTON;
    [button setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    button.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
    [button setTitle:BC_STRING_CONFIRM forState:UIControlStateNormal];
    button.center = CGPointMake(self.view.center.x, self.view.frame.size.height - 8 - BUTTON_HEIGHT/2);
    [self.view addSubview:button];
    [button addTarget:self action:@selector(confirmButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    self.confirmButton = button;
    
    [self disableConfirmButton];
}

- (void)enableConfirmButton
{
    self.confirmButton.enabled = YES;
    [self.confirmButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [self.confirmButton setBackgroundColor:COLOR_BLOCKCHAIN_LIGHT_BLUE];
}

- (void)disableConfirmButton
{
    self.confirmButton.enabled = NO;
    [self.confirmButton setTitleColor:[UIColor grayColor] forState:UIControlStateDisabled];
    [self.confirmButton setBackgroundColor:COLOR_BUTTON_KEYPAD_GRAY];
}

- (void)confirmButtonClicked
{
    BCNavigationController *navigationController = (BCNavigationController *)self.navigationController;
    [navigationController showBusyViewWithLoadingText:BC_STRING_CONFIRMING];
    
    [self performSelector:@selector(shiftPayment) withObject:nil afterDelay:ANIMATION_DURATION];
}

- (void)agreementSwitchChanged:(UISwitch *)agreementSwitch
{
    if (agreementSwitch.on) {
        [self enableConfirmButton];
    } else {
        [self disableConfirmButton];
    }
}

- (void)handleTapView
{
    DLog(@"Terms and conditions tapped");
}

- (void)shiftPayment
{
    [app.wallet shiftPayment];
}

@end

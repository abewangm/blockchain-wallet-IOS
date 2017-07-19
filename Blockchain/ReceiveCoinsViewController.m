//
//  ReceiveCoinsViewControllerViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ReceiveCoinsViewController.h"
#import "RootService.h"
#import "ReceiveTableCell.h"
#import "Address.h"
#import "PrivateKeyReader.h"
#import "UIViewController+AutoDismiss.h"
#import "QRCodeGenerator.h"
#import "BCAddressSelectionView.h"
#import "BCLine.h"
#import "Blockchain-Swift.h"
#import "BCContactRequestView.h"
#import "Contact.h"
#import "UIView+ChangeFrameAttribute.h"

@interface ReceiveCoinsViewController() <UIActivityItemSource, AddressSelectionDelegate, ContactRequestDelegate>
@property (nonatomic) UITextField *lastSelectedField;
@property (nonatomic) QRCodeGenerator *qrCodeGenerator;
@property (nonatomic) uint64_t lastRequestedAmount;
@property (nonatomic) BOOL firstLoading;
@property (nonatomic) BCNavigationController *contactRequestNavigationController;
@end

@implementation ReceiveCoinsViewController

@synthesize activeKeys;

Boolean didClickAccount = NO;
int clickedAccount;

UILabel *mainAddressLabel;

NSString *mainAddress;
NSString *mainLabel;

NSString *detailAddress;
NSString *detailLabel;

#pragma mark - Lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.firstLoading = YES;
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT);
    
    [self setupBottomViews];
    [self selectDefaultDestination];
    
    float imageWidth = 120;
    
    qrCodeMainImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - imageWidth) / 2, 32, imageWidth, imageWidth)];
    qrCodeMainImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self setupTapGestureForMainQR];
    
    // iPhone4/4S
    if (IS_USING_SCREEN_SIZE_4S) {
        int reduceImageSizeBy = 40;
        
        // Smaller QR Code Image
        qrCodeMainImageView.frame = CGRectMake(qrCodeMainImageView.frame.origin.x + reduceImageSizeBy / 2,
                                               qrCodeMainImageView.frame.origin.y - 10,
                                               qrCodeMainImageView.frame.size.width - reduceImageSizeBy,
                                               qrCodeMainImageView.frame.size.height - reduceImageSizeBy);
    }
    
    btcAmountField.placeholder = [NSString stringWithFormat:BTC_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    fiatAmountField.placeholder = [NSString stringWithFormat:FIAT_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    
    [self reload];
    
    [self setupHeaderView];
    
    self.firstLoading = NO;
    
    [self updateUI];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    app.mainTitleLabel.text = BC_STRING_REQUEST;
    
    self.receiveToLabel.textColor = app.wallet.contacts.count > 0 ? COLOR_TEXT_DARK_GRAY : COLOR_LIGHT_GRAY;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self hideKeyboard];
}

- (QRCodeGenerator *)qrCodeGenerator
{
    if (!_qrCodeGenerator) {
        _qrCodeGenerator = [[QRCodeGenerator alloc] init];
    }
    return _qrCodeGenerator;
}

- (void)setupBottomViews
{
    self.bottomContainerView = [[UIView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 260, self.view.frame.size.width, 260)];
    [self.view addSubview:self.bottomContainerView];
    
    UIButton *requestButton = [[UIButton alloc] initWithFrame:CGRectMake(0, self.bottomContainerView.frame.size.height - BUTTON_HEIGHT - 16, self.bottomContainerView.frame.size.width - 30, BUTTON_HEIGHT)];
    requestButton.center = CGPointMake(self.bottomContainerView.center.x, requestButton.center.y);
    [requestButton setTitle:BC_STRING_REQUEST forState:UIControlStateNormal];
    requestButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    requestButton.layer.cornerRadius = CORNER_RADIUS_BUTTON;
    requestButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
    [requestButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [requestButton addTarget:self action:@selector(share) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomContainerView addSubview:requestButton];
    
    BCLine *lineAboveAmounts = [[BCLine alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 1)];
    lineAboveAmounts.backgroundColor = COLOR_LINE_GRAY;
    [self.bottomContainerView addSubview:lineAboveAmounts];

    BCLine *lineBelowAmounts = [[BCLine alloc] initWithFrame:CGRectMake(15, 50, self.view.frame.size.width - 15, 1)];
    lineBelowAmounts.backgroundColor = COLOR_LINE_GRAY;
    [self.bottomContainerView addSubview:lineBelowAmounts];
    
    BCLine *lineBelowToField = [[BCLine alloc] initWithFrame:CGRectMake(15, lineBelowAmounts.frame.origin.y + 50, self.view.frame.size.width - 15, 1)];
    lineBelowToField.backgroundColor = COLOR_LINE_GRAY;
    [self.bottomContainerView addSubview:lineBelowToField];
    
    BCLine *lineBelowFromField = [[BCLine alloc] initWithFrame:CGRectMake(0, lineBelowToField.frame.origin.y + 50, self.view.frame.size.width, 1)];
    lineBelowFromField.backgroundColor = COLOR_LINE_GRAY;
    [self.bottomContainerView addSubview:lineBelowFromField];
    
    CGFloat labelWidth = IS_USING_SCREEN_SIZE_LARGER_THAN_5S ? 48 : 42;
    receiveBtcLabel = [[UILabel alloc] initWithFrame:CGRectMake(lineBelowAmounts.frame.origin.x, 15, labelWidth, 21)];
    receiveBtcLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    receiveBtcLabel.textColor = COLOR_TEXT_DARK_GRAY;
    receiveBtcLabel.text = app.latestResponse.symbol_btc.symbol;
    [self.bottomContainerView addSubview:receiveBtcLabel];
    
    // Field width will be space remaining after subtracting widths of all other subviews and spacing in the row
    CGFloat fieldWidth = (self.view.frame.size.width - labelWidth*2 - 8*6)/2;
    self.receiveBtcField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(receiveBtcLabel.frame.origin.x + receiveBtcLabel.frame.size.width + 8, 10, fieldWidth, 30)];
    self.receiveBtcField.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    self.receiveBtcField.placeholder = [NSString stringWithFormat:BTC_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    self.receiveBtcField.keyboardType = UIKeyboardTypeDecimalPad;
    self.receiveBtcField.inputAccessoryView = amountKeyboardAccessoryView;
    self.receiveBtcField.delegate = self;
    self.receiveBtcField.textColor = COLOR_TEXT_DARK_GRAY;
    [self.bottomContainerView addSubview:self.receiveBtcField];
    
    receiveFiatLabel = [[UILabel alloc] initWithFrame:CGRectMake(self.receiveBtcField.frame.origin.x + self.receiveBtcField.frame.size.width + 8, 15, labelWidth, 21)];
    receiveFiatLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    receiveFiatLabel.textColor = COLOR_TEXT_DARK_GRAY;
    receiveFiatLabel.text = app.latestResponse.symbol_local.code;
    [self.bottomContainerView addSubview:receiveFiatLabel];
    
    CGFloat receiveFiatFieldOriginX = receiveFiatLabel.frame.origin.x + receiveFiatLabel.frame.size.width + 8;
    self.receiveFiatField = [[BCSecureTextField alloc] initWithFrame:CGRectMake(receiveFiatFieldOriginX, 10, fieldWidth, 30)];
    self.receiveFiatField.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    self.receiveFiatField.placeholder = [NSString stringWithFormat:FIAT_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    self.receiveFiatField.textColor = COLOR_TEXT_DARK_GRAY;
    self.receiveFiatField.keyboardType = UIKeyboardTypeDecimalPad;
    self.receiveFiatField.inputAccessoryView = amountKeyboardAccessoryView;
    self.receiveFiatField.delegate = self;
    [self.bottomContainerView addSubview:self.receiveFiatField];
    
    UILabel *toLabel = [[UILabel alloc] initWithFrame:CGRectMake(lineBelowAmounts.frame.origin.x, 65, 50, 21)];
    toLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    toLabel.textColor = COLOR_TEXT_DARK_GRAY;
    toLabel.text = BC_STRING_TO;
    toLabel.adjustsFontSizeToFitWidth = YES;
    [self.bottomContainerView addSubview:toLabel];
    
    UIButton *selectDestinationButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 35, 60, 35, 30)];
    selectDestinationButton.adjustsImageWhenHighlighted = NO;
    [selectDestinationButton setImage:[UIImage imageNamed:@"disclosure"] forState:UIControlStateNormal];
    [selectDestinationButton addTarget:self action:@selector(selectDestination) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomContainerView addSubview:selectDestinationButton];
    
    self.receiveToLabel = [[UILabel alloc] initWithFrame:CGRectMake(toLabel.frame.origin.x + toLabel.frame.size.width + 16, 65, selectDestinationButton.frame.origin.x - (toLabel.frame.origin.x + toLabel.frame.size.width + 16), 21)];
    self.receiveToLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    self.receiveToLabel.textColor = COLOR_LIGHT_GRAY;
    [self.bottomContainerView addSubview:self.receiveToLabel];
    UITapGestureRecognizer *tapGestureReceiveTo = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectDestination)];
    [self.receiveToLabel addGestureRecognizer:tapGestureReceiveTo];
    self.receiveToLabel.userInteractionEnabled = YES;
    
    UILabel *fromLabel = [[UILabel alloc] initWithFrame:CGRectMake(lineBelowToField.frame.origin.x, lineBelowToField.frame.origin.y + 15, 50, 21)];
    fromLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    fromLabel.textColor = COLOR_TEXT_DARK_GRAY;
    fromLabel.text = BC_STRING_FROM;
    fromLabel.adjustsFontSizeToFitWidth = YES;
    [self.bottomContainerView addSubview:fromLabel];
    
    self.receiveFromLabel = [[UILabel alloc] initWithFrame:CGRectMake(fromLabel.frame.origin.x + fromLabel.frame.size.width + 16, lineBelowToField.frame.origin.y + 15, selectDestinationButton.frame.origin.x - (fromLabel.frame.origin.x + fromLabel.frame.size.width + 16), 21)];
    self.receiveFromLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    self.receiveFromLabel.textColor = COLOR_LIGHT_GRAY;
    self.receiveFromLabel.text = BC_STRING_SELECT_CONTACT;
    [self.bottomContainerView addSubview:self.receiveFromLabel];
    UITapGestureRecognizer *tapGestureReceiveFrom = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selectFromClicked)];
    [self.receiveFromLabel addGestureRecognizer:tapGestureReceiveFrom];
    self.receiveFromLabel.userInteractionEnabled = YES;
    
    self.selectFromButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 35,  lineBelowToField.frame.origin.y + 10, 35, 30)];
    self.selectFromButton.adjustsImageWhenHighlighted = NO;
    [self.selectFromButton setImage:[UIImage imageNamed:@"disclosure"] forState:UIControlStateNormal];
    [self.selectFromButton addTarget:self action:@selector(selectFromClicked) forControlEvents:UIControlEventTouchUpInside];
    self.selectFromButton.hidden = YES;
    [self.bottomContainerView addSubview:self.selectFromButton];
    
    self.whatsThisButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 100, lineBelowToField.frame.origin.y + 15, 100, 21)];
    self.whatsThisButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    [self.whatsThisButton setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateNormal];
    [self.whatsThisButton setTitle:BC_STRING_WHATS_THIS forState:UIControlStateNormal];
    [self.whatsThisButton addTarget:self action:@selector(whatsThisButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomContainerView addSubview:self.whatsThisButton];

    CGFloat keyboardFieldWidth = fieldWidth - doneButton.frame.size.width/2;
    btcLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    btcAmountField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];
    fiatLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL];
    fiatAmountField.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_SMALL];

    [btcLabel changeWidth:receiveBtcLabel.frame.size.width];
    btcAmountField.frame = CGRectMake(btcLabel.frame.origin.x + btcLabel.frame.size.width + 8, btcAmountField.frame.origin.y, keyboardFieldWidth, btcAmountField.frame.size.height);
    fiatLabel.frame = CGRectMake(btcAmountField.frame.origin.x + keyboardFieldWidth + 8, fiatLabel.frame.origin.y, receiveFiatLabel.frame.size.width, fiatLabel.frame.size.height);
    fiatAmountField.frame = CGRectMake(fiatLabel.frame.origin.x + fiatLabel.frame.size.width + 8, fiatAmountField.frame.origin.y, keyboardFieldWidth, fiatAmountField.frame.size.height);
    [doneButton setTitle:BC_STRING_DONE forState:UIControlStateNormal];
    doneButton.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)selectDefaultDestination
{
    if ([app.wallet didUpgradeToHd]) {
        [self didSelectToAccount:[app.wallet getFilteredOrDefaultAccountIndex]];
    } else {
        [self didSelectToAddress:[[app.wallet allLegacyAddresses] firstObject]];
    }
}

- (void)setupTapGestureForMainLabel
{
    UITapGestureRecognizer *tapGestureForMainLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainQRClicked:)];
    [mainAddressLabel addGestureRecognizer:tapGestureForMainLabel];
    mainAddressLabel.userInteractionEnabled = YES;
}

- (void)setupTapGestureForMainQR
{
    UITapGestureRecognizer *tapMainQRGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainQRClicked:)];
    [qrCodeMainImageView addGestureRecognizer:tapMainQRGestureRecognizer];
    qrCodeMainImageView.userInteractionEnabled = YES;
}

- (void)reload
{
    [self reloadAddresses];
    
    [self reloadLocalAndBtcSymbolsFromLatestResponse];
    
    if (!mainAddress) {
        [self reloadMainAddress];
    } else if (didClickAccount) {
        [self didSelectFromAccount:clickedAccount];
    } else {
        [self updateUI];
    }
}

- (void)reloadAddresses
{
    self.activeKeys = [app.wallet activeLegacyAddresses];
}

- (void)reloadLocalAndBtcSymbolsFromLatestResponse
{
    if (app.latestResponse.symbol_local && app.latestResponse.symbol_btc) {
        fiatLabel.text = app.latestResponse.symbol_local.code;
        receiveFiatLabel.text = app.latestResponse.symbol_local.code;

        btcLabel.text = app.latestResponse.symbol_btc.symbol;
        receiveBtcLabel.text = app.latestResponse.symbol_btc.symbol;
    }
}

- (void)reloadMainAddress
{
    // Get an address: the first empty receive address for the default HD account
    // Or the first active legacy address if there are no HD accounts
    if ([app.wallet getActiveAccountsCount] > 0) {
        [self didSelectFromAccount:[app.wallet getFilteredOrDefaultAccountIndex]];
    }
    else if (activeKeys.count > 0) {
        for (NSString *address in activeKeys) {
            if (![app.wallet isWatchOnlyLegacyAddress:address]) {
                [self didSelectFromAddress:address];
                break;
            }
        }
    }
}

- (void)setupHeaderView
{
    // Show table header with the QR code of an address from the default account
    float imageWidth = qrCodeMainImageView.frame.size.width;
    
    self.headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, imageWidth + 75 + 4)];
    
    [self.view addSubview:self.headerView];
    
    if ([app.wallet getActiveAccountsCount] > 0 || activeKeys.count > 0) {
        
        qrCodeMainImageView.image = [self.qrCodeGenerator qrImageFromAddress:mainAddress];
        
        [self.headerView addSubview:qrCodeMainImageView];
        
        mainAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, qrCodeMainImageView.frame.origin.y + qrCodeMainImageView.frame.size.height + 8, self.view.frame.size.width - 40, 20)];
        
        mainAddressLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_MEDIUM];
        mainAddressLabel.textAlignment = NSTextAlignmentCenter;
        mainAddressLabel.textColor = COLOR_TEXT_DARK_GRAY;;
        [mainAddressLabel setMinimumScaleFactor:.5f];
        [mainAddressLabel setAdjustsFontSizeToFitWidth:YES];
        [self.headerView addSubview:mainAddressLabel];
        
        [self setupTapGestureForMainLabel];
    }
}

#pragma mark - Helpers

- (NSString *)getAddress:(NSIndexPath*)indexPath
{
    NSString *addr = nil;
    
    if ([indexPath section] == 1)
        addr = [activeKeys objectAtIndex:[indexPath row]];
    
    return addr;
}

- (NSString *)uriURL
{
    double amount = (double)[self getInputAmountInSatoshi] / SATOSHI;
    
    app.btcFormatter.usesGroupingSeparator = NO;
    NSLocale *currentLocale = app.btcFormatter.locale;
    app.btcFormatter.locale = [NSLocale localeWithLocaleIdentifier:LOCALE_IDENTIFIER_EN_US];
    NSString *amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amount]];
    app.btcFormatter.locale = currentLocale;
    app.btcFormatter.usesGroupingSeparator = YES;
    
    return [NSString stringWithFormat:@"bitcoin://%@?amount=%@", self.clickedAddress, amountString];
}

- (uint64_t)getInputAmountInSatoshi
{
    if ([self shouldUseBtcField]) {
        return [app.wallet parseBitcoinValueFromTextField:btcAmountField];
    } else {
        NSString *language = fiatAmountField.textInputMode.primaryLanguage;
        NSLocale *locale = [language isEqualToString:LOCALE_IDENTIFIER_AR] ? [NSLocale localeWithLocaleIdentifier:language] : [NSLocale currentLocale];
        NSString *requestedAmountString = [fiatAmountField.text stringByReplacingOccurrencesOfString:[locale objectForKey:NSLocaleDecimalSeparator] withString:@"."];
        if (![requestedAmountString containsString:@"."]) {
            requestedAmountString = [requestedAmountString stringByReplacingOccurrencesOfString:@"," withString:@"."];
        }
        if (![requestedAmountString containsString:@"."]) {
            requestedAmountString = [requestedAmountString stringByReplacingOccurrencesOfString:@"٫" withString:@"."];
        }
        return app.latestResponse.symbol_local.conversion * [requestedAmountString doubleValue];
    }
    
    return 0;
}

- (BOOL)shouldUseBtcField
{
    BOOL shouldUseBtcField = YES;
    
    if ([btcAmountField isFirstResponder]) {
        shouldUseBtcField = YES;
    } else if ([fiatAmountField isFirstResponder]) {
        shouldUseBtcField = NO;
        
    } else if (self.lastSelectedField == btcAmountField) {
        shouldUseBtcField = YES;
    } else if (self.lastSelectedField == fiatAmountField) {
        shouldUseBtcField = NO;
    }
    
    return shouldUseBtcField;
}

- (void)doCurrencyConversion
{
    [self doCurrencyConversionWithAmount:[self getInputAmountInSatoshi]];
}

- (void)doCurrencyConversionWithAmount:(uint64_t)amount
{
    if ([self shouldUseBtcField]) {
        fiatAmountField.text = [NSNumberFormatter formatAmount:amount localCurrency:YES];
    } else {
        btcAmountField.text = [NSNumberFormatter formatAmount:amount localCurrency:NO];
    }
    
    self.receiveFiatField.text = fiatAmountField.text;
    self.receiveBtcField.text = btcAmountField.text;
}

- (NSString *)getKey:(NSIndexPath*)indexPath
{
    NSString *key;
    
    if ([indexPath section] == 0)
        key = [activeKeys objectAtIndex:[indexPath row]];
    
    return key;
}

- (void)setQRPayment
{
    uint64_t amount = [self getInputAmountInSatoshi];
    double amountAsDouble = (double)amount / SATOSHI;
        
    UIImage *image = [self.qrCodeGenerator qrImageFromAddress:self.clickedAddress amount:amountAsDouble];
        
    qrCodeMainImageView.image = image;
    qrCodeMainImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self doCurrencyConversionWithAmount:amount];
}

- (void)animateTextOfLabel:(UILabel *)labelToAnimate fromText:(NSString *)originalText toIntermediateText:(NSString *)intermediateText speed:(float)speed gestureReceiver:(UIView *)gestureReceiver
{
    gestureReceiver.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        labelToAnimate.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            labelToAnimate.text = intermediateText;
            labelToAnimate.alpha = 1.0;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(speed * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                    labelToAnimate.alpha = 0.0;
                } completion:^(BOOL finished) {
                    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                        labelToAnimate.text = originalText;
                        labelToAnimate.alpha = 1.0;
                        gestureReceiver.userInteractionEnabled = YES;
                    }];
                }];
            });
        }];
    }];
}

#pragma mark - Actions

- (IBAction)doneButtonClicked:(UIButton *)sender
{
    [self hideKeyboard];
}

- (IBAction)labelSaveClicked:(id)sender
{
    NSString *label = [labelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (![app.wallet didUpgradeToHd]) {
        NSMutableCharacterSet *allowedCharSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
        [allowedCharSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
        
        if ([label rangeOfCharacterFromSet:[allowedCharSet invertedSet]].location != NSNotFound) {
            [app standardNotify:BC_STRING_LABEL_MUST_BE_ALPHANUMERIC];
            return;
        }
    }

    NSString *addr = self.clickedAddress;
    
    [app.wallet setLabel:label forLegacyAddress:addr];
    
    [self reload];
    
    [app closeModalWithTransition:kCATransitionFade];
    
    if (app.wallet.isSyncing) {
        [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    }
}

- (IBAction)mainQRClicked:(id)sender
{
    if ([mainAddress isKindOfClass:[NSString class]]) {
        [UIPasteboard generalPasteboard].string = mainAddress;
        [self animateTextOfLabel:mainAddressLabel fromText:mainAddress toIntermediateText:BC_STRING_COPIED_TO_CLIPBOARD speed:1 gestureReceiver:qrCodeMainImageView];
    } else {
        [app standardNotifyAutoDismissingController:BC_STRING_ERROR_COPYING_TO_CLIPBOARD];
    }
}

- (NSString*)formatPaymentRequestWithAmount:(NSString *)amount url:(NSString*)url
{
    return [NSString stringWithFormat:BC_STRING_PAYMENT_REQUEST_ARGUMENT_ARGUMENT, amount, url];
}

- (NSString*)formatPaymentRequestHTML:(NSString*)url
{
    return [NSString stringWithFormat:BC_STRING_PAYMENT_REQUEST_HTML, url];
}

- (IBAction)archiveAddressClicked:(id)sender
{
    NSString *addr = self.clickedAddress;
    Boolean isArchived = [app.wallet isAddressArchived:addr];
    
    if (isArchived) {
        [app.wallet toggleArchiveLegacyAddress:addr];
    }
    else {
        // Need at least one active address
        if (activeKeys.count == 1 && ![app.wallet hasAccount]) {
            [app closeModalWithTransition:kCATransitionFade];
            
            [app standardNotifyAutoDismissingController:BC_STRING_AT_LEAST_ONE_ACTIVE_ADDRESS];
            
            return;
        }
        
        [app.wallet toggleArchiveLegacyAddress:addr];
    }
    
    [self reload];
    
    [app closeModalWithTransition:kCATransitionFade];
}

- (void)showKeyboard
{
    // Select the entry field
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if ([self.receiveBtcField isFirstResponder]) {
            [btcAmountField becomeFirstResponder];
        } else if ([self.receiveFiatField isFirstResponder]){
            [fiatAmountField becomeFirstResponder];
        } else {
            [labelTextField becomeFirstResponder];
        }
    });
}

- (void)hideKeyboardForced
{
    // When backgrounding the app quickly, the input accessory view can remain visible without a first responder, so force the keyboard to appear before dismissing it
    [fiatAmountField becomeFirstResponder];
    [self hideKeyboard];
}

- (void)hideKeyboard
{
    [fiatAmountField resignFirstResponder];
    [btcAmountField resignFirstResponder];
    [labelTextField resignFirstResponder];
    [self.receiveFiatField resignFirstResponder];
    [self.receiveBtcField resignFirstResponder];
}

- (void)alertUserOfPaymentWithMessage:(NSString *)messageString showBackupReminder:(BOOL)showBackupReminder;
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_PAYMENT_RECEIVED message:messageString preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        
        if (showBackupReminder) {
            [app showBackupReminder:YES];
        } else if ([btcAmountField isFirstResponder] || [fiatAmountField isFirstResponder]) {
            [self showKeyboard];
        }
        
    }]];
    
    [app.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)alertUserOfWatchOnlyAddress:(NSString *)address
{
    UIAlertController *alertForWatchOnly = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING_TITLE message:BC_STRING_WATCH_ONLY_RECEIVE_WARNING preferredStyle:UIAlertControllerStyleAlert];
    [alertForWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self didSelectFromAddress:address];
        [app closeModalWithTransition:kCATransitionFromLeft];
    }]];
    [alertForWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_DONT_SHOW_AGAIN style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_KEY_HIDE_WATCH_ONLY_RECEIVE_WARNING];
        [self didSelectFromAddress:address];
        [app closeModalWithTransition:kCATransitionFromLeft];
    }]];
    [alertForWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    
    [[NSNotificationCenter defaultCenter] addObserver:alertForWatchOnly selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    
    [app.tabViewController presentViewController:alertForWatchOnly animated:YES completion:nil];
}

- (void)storeRequestedAmount
{
    self.lastRequestedAmount = [app.wallet parseBitcoinValueFromTextField:btcAmountField];
}

- (void)updateUI
{
    if (self.firstLoading) return; // UI will be updated when viewDidLoad finishes
    
    if (app.wallet.contacts.count > 0) {
        self.receiveFromLabel.textColor = COLOR_TEXT_DARK_GRAY;
        self.selectFromButton.hidden = NO;
        self.whatsThisButton.hidden = YES;
    } else {
        self.receiveFromLabel.textColor = COLOR_LIGHT_GRAY;
        self.selectFromButton.hidden = YES;
        self.whatsThisButton.hidden = NO;
    }
    
    self.receiveToLabel.text = mainLabel;
    mainAddressLabel.text = mainAddress;
    
    [self setQRPayment];
}

- (void)paymentReceived:(NSDecimalNumber *)amount showBackupReminder:(BOOL)showBackupReminder
{
    u_int64_t amountReceived = [[amount decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:SATOSHI]] longLongValue];
    NSString *btcAmountString = [NSNumberFormatter formatMoney:amountReceived localCurrency:NO];
    NSString *localCurrencyAmountString = [NSNumberFormatter formatMoney:amountReceived localCurrency:YES];
    [self alertUserOfPaymentWithMessage:[[NSString alloc] initWithFormat:@"%@\n%@", btcAmountString,localCurrencyAmountString] showBackupReminder:showBackupReminder];
}

- (void)selectDestination
{
    if (![app.wallet isInitialized]) {
        DLog(@"Tried to access select to screen when not initialized!");
        return;
    }
    
    [self hideKeyboard];
    
    BCAddressSelectionView *addressSelectionView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet selectMode:SelectModeReceiveTo];
    addressSelectionView.delegate = self;
    
    [app showModalWithContent:addressSelectionView closeType:ModalCloseTypeBack showHeader:YES headerText:BC_STRING_RECEIVE_TO onDismiss:nil onResume:nil];
}

- (void)whatsThisButtonClicked
{
    
}

- (void)selectFromClicked
{
    if (![app.wallet isInitialized]) {
        DLog(@"Tried to access request button when not initialized!");
        return;
    }
    
    uint64_t amountInSatoshi = [self getInputAmountInSatoshi];
    uint64_t dust = [app.wallet dust];
    
    if (amountInSatoshi == 0) {
        [app standardNotify:BC_STRING_INVALID_SEND_VALUE];
        return;
    } else if (amountInSatoshi < dust) {
        [app standardNotify:[NSString stringWithFormat:BC_STRING_MUST_BE_ABOVE_OR_EQUAL_TO_DUST_THRESHOLD, dust]];
        return;
    }
    
    BCAddressSelectionView *addressSelectionView = [[BCAddressSelectionView alloc] initWithWallet:app.wallet selectMode:SelectModeContact];
    addressSelectionView.delegate = self;
    
    [app showModalWithContent:addressSelectionView closeType:ModalCloseTypeBack showHeader:YES headerText:BC_STRING_REQUEST_FROM onDismiss:nil onResume:nil];
}

- (void)share
{
    if (![app.wallet isInitialized]) {
        DLog(@"Tried to access share button when not initialized!");
        return;
    }
    
    uint64_t amount = [self getInputAmountInSatoshi];
    NSString *amountString = amount > 0 ? [NSNumberFormatter formatMoney:[self getInputAmountInSatoshi] localCurrency:NO] : [BC_STRING_AMOUNT lowercaseString];
    NSString *message = [self formatPaymentRequestWithAmount:amountString url:@""];
    
    NSURL *url = [NSURL URLWithString:[self uriURL]];
    
    NSArray *activityItems = @[message, self, url];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    activityViewController.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypePostToFacebook];
    
    [activityViewController setValue:BC_STRING_PAYMENT_REQUEST_SUBJECT forKey:@"subject"];
    
    // Keyboard is behaving a little strangely because of UITextFields in the Keyboard Accessory View
    // This makes it work correctly - resign first Responder for UITextFields inside the Accessory View...
    [btcAmountField resignFirstResponder];
    [fiatAmountField resignFirstResponder];
    
    [app.tabViewController presentViewController:activityViewController animated:YES completion:nil];
}

- (void)clearAmounts
{
    btcAmountField.text = nil;
    fiatAmountField.text = nil;
    self.receiveBtcField.text = nil;
    self.receiveFiatField.text = nil;
}

# pragma mark - UITextField delegates

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
    if (![app.wallet isInitialized]) {
        DLog(@"Tried to access Receive textField when not initialized!");
        return NO;
    }
    
    if (app.slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionAnchoredRight) {
        return NO;
    }
    
    if (textField == self.receiveFiatField) {
        [self showKeyboard];
        return YES;
    } else if (textField == self.receiveBtcField) {
        [self showKeyboard];
        return YES;
    }
    
    if (textField == fiatAmountField || textField == btcAmountField) {
        self.lastSelectedField = textField; 
    }
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField == labelTextField) {
        [self labelSaveClicked:nil];
        return YES;
    }
    
    [textField resignFirstResponder];
    return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (textField == btcAmountField || textField == fiatAmountField) {
        NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
        NSArray  *points = [newString componentsSeparatedByString:@"."];
        NSLocale *locale = [textField.textInputMode.primaryLanguage isEqualToString:LOCALE_IDENTIFIER_AR] ? [NSLocale localeWithLocaleIdentifier:textField.textInputMode.primaryLanguage] : [NSLocale currentLocale];
        NSArray  *commas = [newString componentsSeparatedByString:[locale objectForKey:NSLocaleDecimalSeparator]];
        
        // Only one comma or point in input field allowed
        if ([points count] > 2 || [commas count] > 2)
            return NO;
        
        // Only 1 leading zero
        if (points.count == 1 || commas.count == 1) {
            if (range.location == 1 && ![string isEqualToString:@"."] && ![string isEqualToString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]] && [textField.text isEqualToString:@"0"]) {
                return NO;
            }
        }
        
        // When entering amount in BTC, max 8 decimal places
        if ([btcAmountField isFirstResponder]) {
            // Max number of decimal places depends on bitcoin unit
            NSUInteger maxlength = [@(SATOSHI) stringValue].length - [@(SATOSHI / app.latestResponse.symbol_btc.conversion) stringValue].length;
            
            if (points.count == 2) {
                NSString *decimalString = points[1];
                if (decimalString.length > maxlength) {
                    return NO;
                }
            }
            else if (commas.count == 2) {
                NSString *decimalString = commas[1];
                if (decimalString.length > maxlength) {
                    return NO;
                }
            }
        }
        
        // Fiat currencies have a max of 3 decimal places, most of them actually only 2. For now we will use 2.
        else if ([fiatAmountField isFirstResponder]) {
            if (points.count == 2) {
                NSString *decimalString = points[1];
                if (decimalString.length > 2) {
                    return NO;
                }
            }
            else if (commas.count == 2) {
                NSString *decimalString = commas[1];
                if (decimalString.length > 2) {
                    return NO;
                }
            }
        }
        
        uint64_t amountInSatoshi = 0;

        if (textField == fiatAmountField) {
            // Convert input amount to internal value
            NSString *amountString = [newString stringByReplacingOccurrencesOfString:@"," withString:@"."];
            if (![amountString containsString:@"."]) {
                amountString = [newString stringByReplacingOccurrencesOfString:@"٫" withString:@"."];
            }
            amountInSatoshi = app.latestResponse.symbol_local.conversion * [amountString doubleValue];
        }
        else {
            amountInSatoshi = [app.wallet parseBitcoinValueFromString:newString];
        }
        
        if (amountInSatoshi > BTC_LIMIT_IN_SATOSHI) {
            return NO;
        } else {
            [self performSelector:@selector(setQRPayment) withObject:nil afterDelay:0.1f];
            return YES;
        }
    } else {
        return YES;
    }
}

#pragma mark - UIActivityItemSource Delegate

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    if (activityType == UIActivityTypePostToTwitter) {
        return nil;
    } else {
        return qrCodeMainImageView.image;
    }
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}

#pragma mark - BCAddressSelectionView Delegate

- (void)didSelectFromAddress:(NSString*)address
{
    mainAddress = address;
    NSString *addr = mainAddress;
    NSString *label = [app.wallet labelForLegacyAddress:addr];
    
    self.clickedAddress = addr;
    didClickAccount = NO;
    
    if (label.length > 0) {
        mainLabel = label;
    } else {
        mainLabel = addr;
    }
    
    [self updateUI];
}

- (void)didSelectToAddress:(NSString*)address
{
    [self didSelectFromAddress:address];
}

- (void)didSelectFromAccount:(int)account
{
    mainAddress = [app.wallet getReceiveAddressForAccount:account];
    self.clickedAddress = mainAddress;
    clickedAccount = account;
    didClickAccount = YES;
    
    mainLabel = [app.wallet getLabelForAccount:account];
    
    [self updateUI];
}

- (void)didSelectToAccount:(int)account
{
    [self didSelectFromAccount:account];
}

- (void)didSelectWatchOnlyAddress:(NSString *)address
{
    [self alertUserOfWatchOnlyAddress:address];
}

- (void)didSelectContact:(Contact *)contact
{
    if (!contact.mdid) {
        UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:BC_STRING_CONTACT_ARGUMENT_HAS_NOT_ACCEPTED_INVITATION_YET, contact.name] message:[NSString stringWithFormat:BC_STRING_CONTACT_ARGUMENT_MUST_ACCEPT_INVITATION, contact.name] preferredStyle:UIAlertControllerStyleAlert];
        [errorAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        [app.tabViewController presentViewController:errorAlert animated:YES completion:nil];
    } else {
        [self createReceiveRequest:RequestTypeReceiveReason forContact:contact reason:nil];
    }
}

#pragma mark - Contacts

- (void)createReceiveRequest:(RequestType)requestType forContact:(Contact *)contact reason:(NSString *)reason
{
    BCContactRequestView *contactRequestView = [[BCContactRequestView alloc] initWithContact:contact amount:[self getInputAmountInSatoshi] willSend:NO accountOrAddress:didClickAccount ? [NSNumber numberWithInt:clickedAccount] : self.clickedAddress];
    contactRequestView.delegate = self;
    
    BCModalViewController *modalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:nil view:contactRequestView];
    
    if (requestType == RequestTypeSendReason || requestType == RequestTypeReceiveReason) {
        self.contactRequestNavigationController = [[BCNavigationController alloc] initWithRootViewController:modalViewController title:BC_STRING_RECEIVE];
        [app.tabViewController presentViewController:self.contactRequestNavigationController animated:YES completion:nil];
    } else {
        [self.contactRequestNavigationController pushViewController:modalViewController animated:YES];
    }
}

#pragma mark - Contact Request Delegate

- (void)createReceiveRequestForContact:(Contact *)contact withReason:(NSString *)reason amount:(uint64_t)amount lastSelectedField:(UITextField *)textField
{
    DLog(@"Creating receive request with reason: %@, amount: %lld", reason, amount);
    [textField resignFirstResponder];
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_CREATING_REQUEST];
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.45 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [app.wallet sendPaymentRequest:contact.identifier amount:amount requestId:nil note:reason];
    });
}

- (void)createSendRequestForContact:(Contact *)contact withReason:(NSString *)reason amount:(uint64_t)amount lastSelectedField:(UITextField *)textField
{
    DLog(@"Receive error: created send request");
}

@end

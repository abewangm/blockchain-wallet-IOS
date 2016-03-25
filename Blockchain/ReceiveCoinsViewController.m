//
//  ReceiveCoinsViewControllerViewController.m
//  Blockchain
//
//  Created by Ben Reeves on 17/03/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//

#import "ReceiveCoinsViewController.h"
#import "AppDelegate.h"
#import "ReceiveTableCell.h"
#import "Address.h"
#import "PrivateKeyReader.h"
#import "UIViewController+AutoDismiss.h"
#import "QRCodeGenerator.h"

@interface ReceiveCoinsViewController() <UIActivityItemSource>
@property (nonatomic) id paymentObserver;
@property (nonatomic) UITextField *lastSelectedField;
@property (nonatomic) QRCodeGenerator *qrCodeGenerator;
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
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width,
                                 app.window.frame.size.height - DEFAULT_HEADER_HEIGHT - DEFAULT_FOOTER_HEIGHT);
    
    tableView.backgroundColor = [UIColor whiteColor];
    
    float imageWidth = 190;
    
    qrCodeMainImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - imageWidth) / 2, 25, imageWidth, imageWidth)];
    qrCodeMainImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self setupTapGestureForMainQR];
    
    // The more actions button will be added to the top menu bar
    [moreActionsButton removeFromSuperview];
    moreActionsButton.alpha = 0.0f;
    moreActionsButton.frame = CGRectMake(0, 16, moreActionsButton.frame.size.width, moreActionsButton.frame.size.height);
    
    // iPhone4/4S
    if ([[UIScreen mainScreen] bounds].size.height < 568) {
        int reduceImageSizeBy = 60;
        
        // Smaller QR Code Image
        qrCodeMainImageView.frame = CGRectMake(qrCodeMainImageView.frame.origin.x + reduceImageSizeBy / 2,
                                               qrCodeMainImageView.frame.origin.y - 10,
                                               qrCodeMainImageView.frame.size.width - reduceImageSizeBy,
                                               qrCodeMainImageView.frame.size.height - reduceImageSizeBy);
    }
    
    qrCodePaymentImageView.frame = CGRectMake(qrCodeMainImageView.frame.origin.x,
                                              qrCodeMainImageView.frame.origin.y,
                                              qrCodeMainImageView.frame.size.width,
                                              qrCodeMainImageView.frame.size.height);
    
    [self setupTapGestureForDetailQR];
    
    // iPhone4/4S
    if ([[UIScreen mainScreen] bounds].size.height < 568) {
        // Smaller QR Code Image
        qrCodePaymentImageView.frame = CGRectMake(qrCodeMainImageView.frame.origin.x,
                                               qrCodeMainImageView.frame.origin.y - 10,
                                               qrCodeMainImageView.frame.size.width,
                                               qrCodeMainImageView.frame.size.height);
    }
    
    optionsTitleLabel.frame = CGRectMake(optionsTitleLabel.frame.origin.x,
                                         qrCodePaymentImageView.frame.origin.y + qrCodePaymentImageView.frame.size.height + 3,
                                         optionsTitleLabel.frame.size.width,
                                         optionsTitleLabel.frame.size.height);
    
    btcAmountField.placeholder = [NSString stringWithFormat:BTC_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    fiatAmountField.placeholder = [NSString stringWithFormat:FIAT_PLACEHOLDER_DECIMAL_SEPARATOR_ARGUMENT, [[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
    
    [self setupTapGestureForLegacyLabel];
    
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    app.mainTitleLabel.text = BC_STRING_RECEIVE;
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self hideKeyboard];
}

- (void)dealloc
{
    if (self.paymentObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.paymentObserver name:NOTIFICATION_KEY_RECEIVE_PAYMENT object:nil];
        self.paymentObserver = nil;
    }
}

- (QRCodeGenerator *)qrCodeGenerator
{
    if (!_qrCodeGenerator) {
        _qrCodeGenerator = [[QRCodeGenerator alloc] init];
    }
    return _qrCodeGenerator;
}

- (void)setupTapGestureForLegacyLabel
{
    UITapGestureRecognizer *tapGestureForLegacyLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showLegacyAddressOnTap)];
    [optionsTitleLabel addGestureRecognizer:tapGestureForLegacyLabel];
    optionsTitleLabel.userInteractionEnabled = YES;
}

- (void)setupTapGestureForMainLabel
{
    UITapGestureRecognizer *tapGestureForMainLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(showMainAddressOnTap)];
    [mainAddressLabel addGestureRecognizer:tapGestureForMainLabel];
    mainAddressLabel.userInteractionEnabled = YES;
}

- (void)setupTapGestureForMainQR
{
    UITapGestureRecognizer *tapMainQRGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainQRClicked:)];
    [qrCodeMainImageView addGestureRecognizer:tapMainQRGestureRecognizer];
    qrCodeMainImageView.userInteractionEnabled = YES;
}

- (void)setupTapGestureForDetailQR
{
    UITapGestureRecognizer *tapDetailQRGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(moreActionsClicked:)];
    [qrCodePaymentImageView addGestureRecognizer:tapDetailQRGestureRecognizer];
    qrCodePaymentImageView.userInteractionEnabled = YES;
}

- (void)reload
{
    [self reloadAddresses];
    
    [self reloadLocalAndBtcSymbolsFromLatestResponse];
    
    [self reloadMainAddress];
    
    [self reloadHeaderView];
    
    [tableView reloadData];
}

- (void)reloadAddresses
{
    self.activeKeys = [app.wallet activeLegacyAddresses];
}

- (void)reloadLocalAndBtcSymbolsFromLatestResponse
{
    if (app.latestResponse.symbol_local && app.latestResponse.symbol_btc) {
        fiatLabel.text = app.latestResponse.symbol_local.code;
        btcLabel.text = app.latestResponse.symbol_btc.symbol;
    }
}

- (void)reloadMainAddress
{
    // Get an address: the first empty receive address for the default HD account
    // Or the first active legacy address if there are no HD accounts
    if ([app.wallet getActiveAccountsCount] > 0) {
        int defaultAccountIndex = [app.wallet getDefaultAccountIndex];
        mainAddress = [app.wallet getReceiveAddressForAccount:defaultAccountIndex];
    }
    else if (activeKeys.count > 0) {
        for (NSString *address in activeKeys) {
            if (![app.wallet isWatchOnlyLegacyAddress:address]) {
                mainAddress = address;
                break;
            }
        }
    }
}

- (void)reloadHeaderView
{
    // Show table header with the QR code of an address from the default account
    float imageWidth = qrCodeMainImageView.frame.size.width;
    
    UIView *headerView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, imageWidth + 50)];
    
    if ([app.wallet getActiveAccountsCount] > 0 || activeKeys.count > 0) {
        
        qrCodeMainImageView.image = [self.qrCodeGenerator qrImageFromAddress:mainAddress];
        
        [headerView addSubview:qrCodeMainImageView];
        
        // Label of the default HD account
        mainAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, imageWidth + 30, self.view.frame.size.width - 40, 18)];
        if ([app.wallet getActiveAccountsCount] > 0) {
            int defaultAccountIndex = [app.wallet getDefaultAccountIndex];
            mainLabel = [app.wallet getLabelForAccount:defaultAccountIndex];
        }
        // Label of the default legacy address
        else {
            NSString *label = [app.wallet labelForLegacyAddress:mainAddress];
            if (label.length > 0) {
                mainLabel = label;
            }
            else {
                mainLabel = mainAddress;
            }
        }
        
        mainAddressLabel.text = mainLabel;
        
        mainAddressLabel.font = [UIFont systemFontOfSize:15];
        mainAddressLabel.textAlignment = NSTextAlignmentCenter;
        mainAddressLabel.textColor = [UIColor blackColor];
        [mainAddressLabel setMinimumScaleFactor:.5f];
        [mainAddressLabel setAdjustsFontSizeToFitWidth:YES];
        [headerView addSubview:mainAddressLabel];
        
        [self setupTapGestureForMainLabel];
    }
    
    tableView.tableHeaderView = headerView;
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
    app.btcFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US"];
    NSString *amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amount]];
    app.btcFormatter.locale = currentLocale;
    app.btcFormatter.usesGroupingSeparator = YES;
    
    return [NSString stringWithFormat:@"bitcoin://%@?amount=%@", self.clickedAddress, amountString];
}

- (uint64_t)getInputAmountInSatoshi
{
    if ([btcAmountField isFirstResponder]) {
        NSString *requestedAmountString = [btcAmountField.text stringByReplacingOccurrencesOfString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator] withString:@"."];
        return [app.wallet parseBitcoinValue:requestedAmountString];
    }
    else if ([fiatAmountField isFirstResponder]) {
        NSString *requestedAmountString = [fiatAmountField.text stringByReplacingOccurrencesOfString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator] withString:@"."];
        return app.latestResponse.symbol_local.conversion * [requestedAmountString doubleValue];
    }
    
    return 0;
}

- (void)doCurrencyConversion
{
    uint64_t amount = [self getInputAmountInSatoshi];
    
    if ([btcAmountField isFirstResponder]) {
        fiatAmountField.text = [app formatAmount:amount localCurrency:YES];
    }
    else if ([fiatAmountField isFirstResponder]) {
        btcAmountField.text = [app formatAmount:amount localCurrency:NO];
    }
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
    double amount = (double)[self getInputAmountInSatoshi] / SATOSHI;
        
    UIImage *image = [self.qrCodeGenerator qrImageFromAddress:self.clickedAddress amount:amount];
        
    qrCodePaymentImageView.image = image;
    qrCodePaymentImageView.contentMode = UIViewContentModeScaleAspectFit;
    
    [self doCurrencyConversion];
}

- (void)animateTextOfLabel:(UILabel *)labelToAnimate toIntermediateText:(NSString *)intermediateText speed:(float)speed gestureReceiver:(UIView *)gestureReceiver
{
    gestureReceiver.userInteractionEnabled = NO;
    
    NSString *originalText = labelToAnimate.text;
    
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

- (void)animateTextOfLabel:(UILabel *)labelToAnimate toFinalText:(NSString *)finalText
{
    labelToAnimate.userInteractionEnabled = NO;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        labelToAnimate.alpha = 0.0;
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            labelToAnimate.text = finalText;
            labelToAnimate.alpha = 1.0;
            labelToAnimate.userInteractionEnabled = YES;
        }];
    }];
}

- (void)toggleTextOfLabel:(UILabel *)labelToAnimate betweenString:(NSString *)firstString andString:(NSString *)secondString
{
    if ([labelToAnimate.text isEqualToString:firstString]) {
        [self animateTextOfLabel:labelToAnimate toFinalText:secondString];
    } else if ([labelToAnimate.text isEqualToString:secondString]) {
        [self animateTextOfLabel:labelToAnimate toFinalText:firstString];
    }
}

#pragma mark - Actions

- (void)showMainAddressOnTap
{
    [self toggleTextOfLabel:mainAddressLabel betweenString:mainLabel andString:mainAddress];
}

- (void)showLegacyAddressOnTap
{
    // If the address has no label, no need to animate
    if (![detailLabel isEqualToString:detailAddress]) {
        [self toggleTextOfLabel:optionsTitleLabel betweenString:detailAddress andString:detailLabel];
    }
}

- (IBAction)moreActionsClicked:(id)sender
{
    [UIPasteboard generalPasteboard].string = detailAddress;
    [self animateTextOfLabel:optionsTitleLabel toIntermediateText:BC_STRING_COPIED_TO_CLIPBOARD speed:1 gestureReceiver:qrCodePaymentImageView];
}

- (IBAction)shareClicked:(id)sender
{
    [self disableTapInteraction];

    NSString *message = [self formatPaymentRequest:@""];
    
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
    
    [[NSNotificationCenter defaultCenter] addObserver:activityViewController selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *error) {
        [self showKeyboard];
        
        // Allow keyboard to complete animating before allowing an action sheet
        [self performSelector:@selector(enableTapInteraction) withObject:nil afterDelay:0.2f];
    };
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
    [UIPasteboard generalPasteboard].string = mainAddress;
    
    [self animateTextOfLabel:mainAddressLabel toIntermediateText:BC_STRING_COPIED_TO_CLIPBOARD speed:1 gestureReceiver:qrCodeMainImageView];
}

- (IBAction)copyAddressClicked:(id)sender
{
    [UIPasteboard generalPasteboard].string = detailAddress;
    
    [self animateTextOfLabel:optionsTitleLabel toIntermediateText:BC_STRING_COPIED_TO_CLIPBOARD speed:1 gestureReceiver:optionsTitleLabel];
}

- (NSString*)formatPaymentRequest:(NSString*)url
{
    return [NSString stringWithFormat:BC_STRING_PAYMENT_REQUEST, url];
}

- (NSString*)formatPaymentRequestHTML:(NSString*)url
{
    return [NSString stringWithFormat:BC_STRING_PAYMENT_REQUEST_HTML, url];
}

- (IBAction)labelAddressClicked:(id)sender
{
    NSString *addr = self.clickedAddress;
    NSString *label = [app.wallet labelForLegacyAddress:addr];
    
    labelAddressLabel.text = addr;
    
    if (label && label.length > 0) {
        labelTextField.text = label;
    }
    
    UIButton *saveButton = [UIButton buttonWithType:UIButtonTypeCustom];
    saveButton.frame = CGRectMake(0, 0, self.view.frame.size.width, 46);
    saveButton.backgroundColor = COLOR_BUTTON_GRAY;
    [saveButton setTitle:BC_STRING_SAVE forState:UIControlStateNormal];
    [saveButton setTitleColor:[UIColor darkGrayColor] forState:UIControlStateNormal];
    saveButton.titleLabel.font = [UIFont systemFontOfSize:17.0];
    
    [saveButton addTarget:self action:@selector(labelSaveClicked:) forControlEvents:UIControlEventTouchUpInside];
    
    [labelTextField setReturnKeyType:UIReturnKeyDone];
    labelTextField.delegate = self;
    
    labelTextField.inputAccessoryView = saveButton;
    
    BOOL isAlertPresented = [app.window.rootViewController.presentedViewController isMemberOfClass:[UIAlertController class]];
    
    [app showModalWithContent:labelAddressView closeType:ModalCloseTypeClose headerText:BC_STRING_LABEL_ADDRESS onDismiss:^() {
        self.clickedAddress = nil;
        labelTextField.text = nil;
    } onResume:nil];
    
    if (!isAlertPresented) {
        [labelTextField becomeFirstResponder];
    }
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

- (void)disableTapInteraction
{
    moreActionsButton.userInteractionEnabled = NO;
    qrCodePaymentImageView.userInteractionEnabled = NO;
}

- (void)enableTapInteraction
{
    moreActionsButton.userInteractionEnabled = YES;
    qrCodePaymentImageView.userInteractionEnabled = YES;
}

- (void)showKeyboard
{
    [entryField becomeFirstResponder];
    
    // Select the entry field
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        
        if ([entryField isFirstResponder]) {
            self.lastSelectedField == nil ? [fiatAmountField becomeFirstResponder] : [self.lastSelectedField becomeFirstResponder];
        } else {
            [labelTextField becomeFirstResponder];
        }
    });
}

- (void)hideKeyboard
{
    [fiatAmountField resignFirstResponder];
    [btcAmountField resignFirstResponder];
    [labelTextField resignFirstResponder];
    [entryField resignFirstResponder];
}

- (void)alertUserOfPaymentWithMessage:(NSString *)messageString
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_PAYMENT_RECEIVED message:messageString delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
    [alertView show];
}

- (void)alertUserOfWatchOnlyAddress
{
    UIAlertController *alertForWatchOnly = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING_TITLE message:BC_STRING_WATCH_ONLY_RECEIVE_WARNING preferredStyle:UIAlertControllerStyleAlert];
    [alertForWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self showReceiveModal];
    }]];
    [alertForWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_DONT_SHOW_AGAIN style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [[NSUserDefaults standardUserDefaults] setObject:[NSNumber numberWithBool:YES] forKey:USER_DEFAULTS_KEY_HIDE_WATCH_ONLY_RECEIVE_WARNING];
        [self showReceiveModal];
    }]];
    [alertForWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    
    [[NSNotificationCenter defaultCenter] addObserver:alertForWatchOnly selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    
    [app.tabViewController presentViewController:alertForWatchOnly animated:YES completion:nil];
}

- (void)showReceiveModal
{
    [self startObservingForReceivedPayment];
    
    optionsTitleLabel.text = detailLabel;
    
    [app showModalWithContent:requestCoinsView closeType:ModalCloseTypeClose headerText:BC_STRING_REQUEST_AMOUNT onDismiss:^() {
        // Remove the extra menu item (more actions)
        [moreActionsButton removeFromSuperview];
        moreActionsButton.alpha = 0.0f;
        
        if (self.paymentObserver) {
            [[NSNotificationCenter defaultCenter] removeObserver:self.paymentObserver name:NOTIFICATION_KEY_RECEIVE_PAYMENT object:nil];
            self.paymentObserver = nil;
        }
        
    } onResume:^() {
        // Reset the requested amount when showing the request screen
        btcAmountField.text = nil;
        fiatAmountField.text = nil;
        
        [self enableTapInteraction];
        
        // Show an extra menu item (more actions)
        [app.modalView addSubview:moreActionsButton];
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            moreActionsButton.alpha = 1.0f;
        }];
    }];
    
    [self setQRPayment];
    
    entryField.inputAccessoryView = amountKeyboardAccessoryView;
    
    [self showKeyboard];
}

- (void)startObservingForReceivedPayment
{
    __weak ReceiveCoinsViewController *weakSelf = self;
    
    self.paymentObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_RECEIVE_PAYMENT object:nil queue:nil usingBlock:^(NSNotification *note) {
        NSDecimalNumber *amountReceivedDecimalNumber = note.userInfo[DICTIONARY_KEY_AMOUNT];
        u_int64_t amountReceived = [[amountReceivedDecimalNumber decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:SATOSHI]] longLongValue];
        
        NSString *convertedBitcoinString = [btcAmountField.text stringByReplacingOccurrencesOfString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator] withString:@"."];
        
        if ([app stringHasBitcoinValue:convertedBitcoinString]) {
            NSDecimalNumber *amountRequestedDecimalNumber = [NSDecimalNumber decimalNumberWithString:convertedBitcoinString];
            u_int64_t amountRequested = [[amountRequestedDecimalNumber decimalNumberByMultiplyingBy:(NSDecimalNumber *)[NSDecimalNumber numberWithDouble:SATOSHI]] longLongValue];
            amountRequested = app.latestResponse.symbol_btc.conversion * amountRequested / SATOSHI;
            
            if (amountReceived == amountRequested) {
                NSString *btcAmountString = [btcAmountField.text stringByReplacingOccurrencesOfString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator] withString:@"."];
                u_int64_t btcAmount = [app.wallet parseBitcoinValue:btcAmountString];
                btcAmountString = [app formatMoney:btcAmount localCurrency:NO];
                NSString *localCurrencyAmountString = [btcAmountField.text stringByReplacingOccurrencesOfString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator] withString:@"."];
                u_int64_t currencyAmount = [app.wallet parseBitcoinValue:localCurrencyAmountString];
                localCurrencyAmountString = [app formatMoney:currencyAmount localCurrency:YES];
                [weakSelf alertUserOfPaymentWithMessage:[[NSString alloc] initWithFormat:@"%@\n%@", btcAmountString, localCurrencyAmountString]];
            }
        }
        
        if (didClickAccount) {
            detailAddress = [app.wallet getReceiveAddressForAccount:clickedAccount];
            weakSelf.clickedAddress = detailAddress;
            [weakSelf setQRPayment];
            [weakSelf animateTextOfLabel:optionsTitleLabel toFinalText:detailLabel];
        }

    }];
}

# pragma mark - UITextField delegates

- (BOOL)textFieldShouldBeginEditing:(UITextField *)textField
{
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
        NSArray  *commas = [newString componentsSeparatedByString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator]];
        
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
        NSString *amountString = [newString stringByReplacingOccurrencesOfString:[[NSLocale currentLocale] objectForKey:NSLocaleDecimalSeparator] withString:@"."];
        if (textField == fiatAmountField) {
            amountInSatoshi = app.latestResponse.symbol_local.conversion * [amountString doubleValue];
        }
        else {
            amountInSatoshi = [app.wallet parseBitcoinValue:amountString];
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

#pragma mark - UITableview Delegates

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    didClickAccount = (indexPath.section == 0);
    
    if (indexPath.section == 0) {
        int row = (int) indexPath.row;
        detailAddress = [app.wallet getReceiveAddressForAccount:[app.wallet getIndexOfActiveAccount:row]];
        self.clickedAddress = detailAddress;
        clickedAccount = [app.wallet getIndexOfActiveAccount:row];
        
        detailLabel = [app.wallet getLabelForAccount:[app.wallet getIndexOfActiveAccount:row]];
    }
    else {
        detailAddress = [self getAddress:indexPath];
        NSString *addr = detailAddress;
        NSString *label = [app.wallet labelForLegacyAddress:addr];
        
        self.clickedAddress = addr;
        
        if (label.length > 0)
            detailLabel = label;
        else
            detailLabel = addr;
        
        if ([app.wallet isWatchOnlyLegacyAddress:addr] && ![[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_HIDE_WATCH_ONLY_RECEIVE_WARNING]) {
            [self alertUserOfWatchOnlyAddress];
            return;
        }
    }
    
    [self showReceiveModal];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        return 44.0f;
    }
    
    return 70.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0) {
        return 12.0f;
    }
    
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 45)];
    view.backgroundColor = [UIColor whiteColor];
    
    if (section == 0) {
        return nil;
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width, 14)];
    label.textColor = COLOR_FOREGROUND_GRAY;
    label.font = [UIFont systemFontOfSize:14.0];
    
    [view addSubview:label];
    
    NSString *labelString;
    
    if (section == 0)
        labelString = nil;
    else if (section == 1) {
        labelString = BC_STRING_IMPORTED_ADDRESSES;
    }
    else if (section == 2)
        labelString = BC_STRING_IMPORTED_ADDRESSES_ARCHIVED;
    else
        @throw @"Unknown Section";
    
    label.text = [labelString uppercaseString];
    
    return view;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if (section == 0)
        return [app.wallet getActiveAccountsCount];
    else
        return [activeKeys count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 2;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        int accountIndex = [app.wallet getIndexOfActiveAccount:(int)indexPath.row];
        NSString *accountLabelString = [app.wallet getLabelForAccount:accountIndex];
        
        ReceiveTableCell *cell = [tableView dequeueReusableCellWithIdentifier:@"receiveAccount"];
        
        if (cell == nil) {
            cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
            cell.backgroundColor = COLOR_BACKGROUND_GRAY;
        
            // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
            cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
            cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 217, cell.frame.size.height-(cell.frame.size.height-cell.balanceLabel.frame.origin.y-cell.balanceLabel.frame.size.height), 0);
            cell.balanceButton.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, contentInsets);
            
            [cell.watchLabel setHidden:TRUE];
        }
        
        cell.labelLabel.text = accountLabelString;
        cell.addressLabel.text = @"";
        
        uint64_t balance = [app.wallet getBalanceForAccount:accountIndex];
        
        // Selected cell color
        UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
        [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
        [cell setSelectedBackgroundView:v];
        
        cell.balanceLabel.text = [app formatMoney:balance];
        cell.balanceLabel.minimumScaleFactor = 0.75f;
        [cell.balanceLabel setAdjustsFontSizeToFitWidth:YES];
        
        [cell.balanceButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
        
        return cell;
    }
    
    NSString *addr = [self getAddress:indexPath];
    
    Boolean isWatchOnlyLegacyAddress = [app.wallet isWatchOnlyLegacyAddress:addr];
    
    ReceiveTableCell *cell;
    if (isWatchOnlyLegacyAddress) {
        cell = [tableView dequeueReusableCellWithIdentifier:@"receiveWatchOnly"];
    }
    else {
        cell = [tableView dequeueReusableCellWithIdentifier:@"receiveNormal"];
    }
    
    if (cell == nil) {
        cell = [[[NSBundle mainBundle] loadNibNamed:@"ReceiveCell" owner:nil options:nil] objectAtIndex:0];
        cell.backgroundColor = COLOR_BACKGROUND_GRAY;
        
        if (isWatchOnlyLegacyAddress) {
            // Show the watch only tag and resize the label and balance labels so there is enough space
            cell.labelLabel.frame = CGRectMake(20, 11, 148, 21);
            
            cell.balanceLabel.frame = CGRectMake(254, 11, 83, 21);
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 254, cell.frame.size.height-(cell.frame.size.height-cell.balanceLabel.frame.origin.y-cell.balanceLabel.frame.size.height), 0);
            cell.balanceButton.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, contentInsets);
            
            [cell.watchLabel setHidden:FALSE];
        }
        else {
            // Don't show the watch only tag and resize the label and balance labels to use up the freed up space
            cell.labelLabel.frame = CGRectMake(20, 11, 185, 21);
            
            cell.balanceLabel.frame = CGRectMake(217, 11, 120, 21);
            UIEdgeInsets contentInsets = UIEdgeInsetsMake(0, 217, cell.frame.size.height-(cell.frame.size.height-cell.balanceLabel.frame.origin.y-cell.balanceLabel.frame.size.height), 0);
            cell.balanceButton.frame = UIEdgeInsetsInsetRect(cell.contentView.frame, contentInsets);
            
            [cell.watchLabel setHidden:TRUE];
        }
    }
    
    NSString *label =  [app.wallet labelForLegacyAddress:addr];
    
    if (label)
        cell.labelLabel.text = label;
    else
        cell.labelLabel.text = BC_STRING_NO_LABEL;
    
    cell.addressLabel.text = addr;
    
    uint64_t balance = [app.wallet getLegacyAddressBalance:addr];
    
    // Selected cell color
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0,0,cell.frame.size.width,cell.frame.size.height)];
    [v setBackgroundColor:COLOR_BLOCKCHAIN_BLUE];
    [cell setSelectedBackgroundView:v];
    
    cell.balanceLabel.text = [app formatMoney:balance];
    cell.balanceLabel.minimumScaleFactor = 0.75f;
    [cell.balanceLabel setAdjustsFontSizeToFitWidth:YES];
    
    [cell.balanceButton addTarget:app action:@selector(toggleSymbol) forControlEvents:UIControlEventTouchUpInside];
    
    return cell;
}

#pragma mark - UIActivityItemSource Delegate

- (id)activityViewController:(UIActivityViewController *)activityViewController itemForActivityType:(NSString *)activityType
{
    if (activityType == UIActivityTypePostToTwitter) {
        return nil;
    } else {
        return qrCodePaymentImageView.image;
    }
}

- (id)activityViewControllerPlaceholderItem:(UIActivityViewController *)activityViewController
{
    return @"";
}

@end

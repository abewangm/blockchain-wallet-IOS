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

@interface ReceiveCoinsViewController() <UIAlertViewDelegate, UIActivityItemSource>
@property (nonatomic) id paymentObserver;
@property (nonatomic) double amountRequested;
@property (nonatomic) UIAlertView *addNewAddressAlertView;
@end

@implementation ReceiveCoinsViewController

@synthesize activeKeys;
@synthesize archivedKeys;

Boolean didClickAccount = NO;
int clickedAccount;

UILabel *mainAddressLabel;

NSString *mainAddress;
NSString *mainLabel;

NSString *detailAddress;
NSString *detailLabel;

UIActionSheet *popupAddressUnArchive;
UIActionSheet *popupAddressArchive;

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
    
    [self setupTapGestureForLegacyLabel];
    
    [self setupArchiveActionSheets];
    
    [self reload];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    app.mainTitleLabel.text = BC_STRING_RECEIVE;
}

- (void)dealloc
{
    if (self.paymentObserver) {
        [[NSNotificationCenter defaultCenter] removeObserver:self.paymentObserver name:NOTIFICATION_KEY_RECEIVE_PAYMENT object:nil];
        self.paymentObserver = nil;
    }
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

- (void)setupArchiveActionSheets
{
    popupAddressArchive = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:BC_STRING_CANCEL destructiveButtonTitle:nil otherButtonTitles:
                           BC_STRING_COPY_ADDRESS,
                           BC_STRING_LABEL_ADDRESS,
                           BC_STRING_ARCHIVE_ADDRESS,
                           nil];
    
    popupAddressUnArchive = [[UIActionSheet alloc] initWithTitle:nil delegate:self cancelButtonTitle:BC_STRING_CANCEL destructiveButtonTitle:nil otherButtonTitles:
                             BC_STRING_COPY_ADDRESS,
                             BC_STRING_LABEL_ADDRESS,
                             BC_STRING_UNARCHIVE_ADDRESS,
                             nil];
}

- (void)reload
{
    [self reloadAddresses];
    
    [self reloadLocalAndBtcSymbolsFromLatestResponse];
    
    [self reloadMainAddress];
    
    [self reloadHeaderView];
    
    // Legacy code for generating new addresses
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_NEW_ADDRESS object:nil userInfo:nil];
    
    [tableView reloadData];
}

- (void)reloadAddresses
{
    self.activeKeys = [app.wallet activeLegacyAddresses];
    self.archivedKeys = [app.wallet archivedLegacyAddresses];
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
    if ([app.wallet getAccountsCount] > 0) {
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
    
    if ([app.wallet getAccountsCount] > 0 || activeKeys.count > 0) {
        
        qrCodeMainImageView.image = [self qrImageFromAddress:mainAddress];
        
        [headerView addSubview:qrCodeMainImageView];
        
        // Label of the default HD account
        mainAddressLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, imageWidth + 30, self.view.frame.size.width - 40, 18)];
        if ([app.wallet getAccountsCount] > 0) {
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
    else if ([indexPath section] == 2)
        addr = [archivedKeys objectAtIndex:[indexPath row]];
    
    return addr;
}

- (NSString *)uriURL
{
    double amount = (double)[self getInputAmountInSatoshi] / SATOSHI;
    
    app.btcFormatter.usesGroupingSeparator = NO;
    NSString *amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amount]];
    app.btcFormatter.usesGroupingSeparator = YES;
    
    amountString = [amountString stringByReplacingOccurrencesOfString:@"," withString:@"."];
    
    return [NSString stringWithFormat:@"bitcoin://%@?amount=%@", self.clickedAddress, amountString];
}

- (uint64_t)getInputAmountInSatoshi
{
    if ([btcAmountField isFirstResponder]) {
        NSString *requestedAmountString = [btcAmountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
        return [app.wallet parseBitcoinValue:requestedAmountString];
    }
    else if ([fiatAmountField isFirstResponder]) {
        NSString *requestedAmountString = [fiatAmountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
        return app.latestResponse.symbol_local.conversion * [requestedAmountString doubleValue];
    }
    
    return 0;
}

- (void)doCurrencyConversion
{
    uint64_t amount = [self getInputAmountInSatoshi];
    
    if (amount > BTC_LIMIT_IN_SATOSHI) {
        [self highlightInvalidAmounts];
    } else {
        [self removeHighlightFromAmounts];
    }
    
    if ([btcAmountField isFirstResponder]) {
        fiatAmountField.text = [app formatAmount:amount localCurrency:YES];
    }
    else if ([fiatAmountField isFirstResponder]) {
        btcAmountField.text = [app formatAmount:amount localCurrency:NO];
    }
}

- (void)highlightInvalidAmounts
{
    btcAmountField.textColor = [UIColor redColor];
    fiatAmountField.textColor = [UIColor redColor];
}

- (void)removeHighlightFromAmounts
{
    btcAmountField.textColor = [UIColor blackColor];
    fiatAmountField.textColor = [UIColor blackColor];
}

- (NSString *)getKey:(NSIndexPath*)indexPath
{
    NSString *key;
    
    if ([indexPath section] == 0)
        key = [activeKeys objectAtIndex:[indexPath row]];
    else
        key = [archivedKeys objectAtIndex:[indexPath row]];
    
    return key;
}

- (UIImage *)qrImageFromAddress:(NSString *)address
{
    NSString *addressURL = [NSString stringWithFormat:@"bitcoin:%@", address];
    
    return [self createQRImageFromString:addressURL];
}

- (UIImage *)qrImageFromAddress:(NSString *)address amount:(double)amount
{
    app.btcFormatter.usesGroupingSeparator = NO;
    NSString *amountString = [app.btcFormatter stringFromNumber:[NSNumber numberWithDouble:amount]];
    app.btcFormatter.usesGroupingSeparator = YES;
    
    amountString = [amountString stringByReplacingOccurrencesOfString:@"," withString:@"."];
    
    self.amountRequested = amount;
    
    NSString *addressURL = [NSString stringWithFormat:@"bitcoin:%@?amount=%@", address, amountString];
    
    return [self createQRImageFromString:addressURL];
}

- (UIImage *)createQRImageFromString:(NSString *)string
{
    return [self createNonInterpolatedUIImageFromCIImage:[self createQRFromString:string] withScale:10*[[UIScreen mainScreen] scale]];
}

- (CIImage *)createQRFromString:(NSString *)qrString
{
    // Need to convert the string to a UTF-8 encoded NSData object
    NSData *stringData = [qrString dataUsingEncoding:NSUTF8StringEncoding];
    
    // Create the filter
    CIFilter *qrFilter = [CIFilter filterWithName:@"CIQRCodeGenerator"];
    // Set the message content and error-correction level
    [qrFilter setValue:stringData forKey:@"inputMessage"];
    [qrFilter setValue:@"M" forKey:@"inputCorrectionLevel"];
    
    return qrFilter.outputImage;
}

- (UIImage *)createNonInterpolatedUIImageFromCIImage:(CIImage *)image withScale:(CGFloat)scale
{
    // Render the CIImage into a CGImage
    CGImageRef cgImage = [[CIContext contextWithOptions:nil] createCGImage:image fromRect:image.extent];
    
    // Now we'll rescale using CoreGraphics
    UIGraphicsBeginImageContext(CGSizeMake(image.extent.size.width * scale, image.extent.size.width * scale));
    CGContextRef context = UIGraphicsGetCurrentContext();
    // We don't want to interpolate (since we've got a pixel-correct image)
    CGContextSetInterpolationQuality(context, kCGInterpolationNone);
    CGContextDrawImage(context, CGContextGetClipBoundingBox(context), cgImage);
    
    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
    
    // Tidy up
    UIGraphicsEndImageContext();
    CGImageRelease(cgImage);
    
    // Rotate the image
    UIImage *qrImage = [UIImage imageWithCGImage:[scaledImage CGImage]
                                           scale:[scaledImage scale]
                                     orientation:UIImageOrientationDownMirrored];
    
    return qrImage;
}

- (void)setQRPayment
{
    if ([self getInputAmountInSatoshi] <= BTC_LIMIT_IN_SATOSHI) {
        
        double amount = (double)[self getInputAmountInSatoshi] / SATOSHI;
        
        UIImage *image = [self qrImageFromAddress:self.clickedAddress amount:amount];
        
        qrCodePaymentImageView.image = image;
        qrCodePaymentImageView.contentMode = UIViewContentModeScaleAspectFit;
        
    }
    
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
    if (didClickAccount) {
        [UIPasteboard generalPasteboard].string = detailAddress;
        [self animateTextOfLabel:optionsTitleLabel toIntermediateText:BC_STRING_COPIED_TO_CLIPBOARD speed:1 gestureReceiver:qrCodePaymentImageView];
    }
    else {
        if ([archivedKeys containsObject:self.clickedAddress]) {
            [popupAddressUnArchive showInView:[UIApplication sharedApplication].keyWindow];
        }
        else {
            [popupAddressArchive showInView:[UIApplication sharedApplication].keyWindow];
        }
        [self hideKeyboard];
    }
}

- (IBAction)shareClicked:(id)sender
{
    NSString *message = [self formatPaymentRequest:@""];
    NSURL *url = [NSURL URLWithString:[self uriURL]];
    NSArray *activityItems = @[message, self, url];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    activityViewController.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList];
    
    [activityViewController setValue:BC_STRING_PAYMENT_REQUEST_SUBJECT forKey:@"subject"];
    
    // Keyboard is behaving a little strangely because of UITextFields in the Keyboard Accessory View
    // This makes it work correctly - resign first Responder for UITextFields inside the Accessory View...
    [btcAmountField resignFirstResponder];
    [fiatAmountField resignFirstResponder];
    
    [app.tabViewController presentViewController:activityViewController animated:YES completion:nil];
    
    activityViewController.completionWithItemsHandler = ^(NSString *activityType, BOOL completed, NSArray *returnedItems, NSError *error) {
        [self showKeyboard];
    };
}

- (IBAction)addNewAddressClicked:(id)sender
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_NEW_ADDRESS message:nil delegate:self cancelButtonTitle:BC_STRING_CANCEL otherButtonTitles:BC_STRING_NEW_ADDRESS_GENERATE_NEW, BC_STRING_NEW_ADDRESS_SCAN_QR_CODE, nil];
    alertView.delegate = self;
    self.addNewAddressAlertView = alertView;
    [alertView show];
    
}

- (IBAction)labelSaveClicked:(id)sender
{
    NSString *label = [labelTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSMutableCharacterSet *allowedCharSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [allowedCharSet formUnionWithCharacterSet:[NSCharacterSet whitespaceCharacterSet]];
     
    if ([label rangeOfCharacterFromSet:[allowedCharSet invertedSet]].location != NSNotFound) {
        [app standardNotify:BC_STRING_LABEL_MUST_BE_ALPHANUMERIC];
        return;
    }
    
    NSString *addr = self.clickedAddress;
    
    [app.wallet setLabel:label forLegacyAddress:addr];
    
    [self reload];
    
    [app closeModalWithTransition:kCATransitionFade];
    
    // Show busy view since syncWallet will block the main thread
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_UPDATING_LABEL];
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
    
    [app showModalWithContent:labelAddressView closeType:ModalCloseTypeClose headerText:BC_STRING_LABEL_ADDRESS onDismiss:^() {
        self.clickedAddress = nil;
        labelTextField.text = nil;
    } onResume:nil];
    
    [labelTextField becomeFirstResponder];
}

- (IBAction)archiveAddressClicked:(id)sender
{
    NSString *addr = self.clickedAddress;
    Boolean isArchived = [app.wallet isArchived:addr];
    
    if (isArchived) {
        [app.wallet unArchiveLegacyAddress:addr];
    }
    else {
        // Need at least one active address
        if (activeKeys.count == 1 && ![app.wallet hasAccount]) {
            [app closeModalWithTransition:kCATransitionFade];
            
            [app standardNotify:BC_STRING_AT_LEAST_ONE_ACTIVE_ADDRESS];
            
            return;
        }
        
        [app.wallet archiveLegacyAddress:addr];
    }
    
    [self reload];
    
    [app closeModalWithTransition:kCATransitionFade];
}


- (void)showKeyboard
{
    [entryField becomeFirstResponder];
    
    // Select the entry field
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [fiatAmountField becomeFirstResponder];
    });
}

- (void)hideKeyboard
{
    [fiatAmountField resignFirstResponder];
    [btcAmountField resignFirstResponder];
    [entryField resignFirstResponder];
}

- (void)alertUserOfPaymentWithMessage:(NSString *)messageString
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_PAYMENT_RECEIVED message:messageString delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
    [alertView show];
}

- (void)startObservingForReceivedPayment
{
    __weak ReceiveCoinsViewController *weakSelf = self;
    
    self.paymentObserver = [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_RECEIVE_PAYMENT object:nil queue:nil usingBlock:^(NSNotification *note) {
        double amountReceived = [note.userInfo[DICTIONARY_KEY_AMOUNT] doubleValue];
        NSString *amountReceivedString = [[NSString alloc] initWithFormat:@"%.8f", amountReceived];
        double amountRequested = weakSelf.amountRequested;
        NSString *amountRequestedString = [[NSString alloc] initWithFormat:@"%.8f", amountRequested];

        if ([amountReceivedString isEqualToString:amountRequestedString]) {
            NSString *btcAmountString = [btcAmountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
            u_int64_t btcAmount = [app.wallet parseBitcoinValue:btcAmountString];
            btcAmountString = [app formatMoney:btcAmount localCurrency:NO];
            NSString *localCurrencyAmountString = [btcAmountField.text stringByReplacingOccurrencesOfString:@"," withString:@"."];
            u_int64_t currencyAmount = [app.wallet parseBitcoinValue:localCurrencyAmountString];
            localCurrencyAmountString = [app formatMoney:currencyAmount localCurrency:YES];
            [weakSelf alertUserOfPaymentWithMessage:[[NSString alloc] initWithFormat:@"%@\n%@", btcAmountString, localCurrencyAmountString]];
        }
    }];
}

- (void)generateNewAddress
{    
    [app.wallet generateNewKey];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(promptForLabelAfterGenerate)
                                                 name:NOTIFICATION_KEY_NEW_ADDRESS object:nil];
}

- (void)promptForLabelAfterGenerate
{
    //newest address is the last object in activeKeys
    self.clickedAddress = [activeKeys lastObject];
    [self labelAddressClicked:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_NEW_ADDRESS
                                                  object:nil];
}

# pragma mark - UIAlertView delegate

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (alertView == self.addNewAddressAlertView) {
        switch (buttonIndex) {
            case 0: {
                DLog(@"Cancelled creating new address");
                break;
            }
            case 1: {
                DLog(@"Generating new address");
                [self generateNewAddress];
                break;
            }
            case 2: {
                DLog(@"Scan QR code");
                PrivateKeyReader *reader = [[PrivateKeyReader alloc] initWithSuccess:^(NSString* privateKeyString) {
                    [app.wallet addKey:privateKeyString];
                    
                    [app.wallet loading_stop];
                } error:nil];
                
                [app.slidingViewController presentViewController:reader animated:YES completion:nil];

                break;
            }
        }
    }
}

# pragma mark - UIActionSheet delegate

- (void)actionSheet:(UIActionSheet *)popup clickedButtonAtIndex:(NSInteger)buttonIndex
{
    switch (buttonIndex) {
        case 0:
            [self copyAddressClicked:nil];
            [self showKeyboard];
            break;
        case 1:
            [self labelAddressClicked:nil];
            [self hideKeyboard];
            break;
        case 2:
            [self archiveAddressClicked:nil];
            [self hideKeyboard];
            break;

        default:
            [self showKeyboard];
            break;
    }
}

# pragma mark - UITextField delegates

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
    NSString *newString = [textField.text stringByReplacingCharactersInRange:range withString:string];
    NSArray  *points = [newString componentsSeparatedByString:@"."];
    NSArray  *commas = [newString componentsSeparatedByString:@","];
    
    // Only one comma or point in input field allowed
    if ([points count] > 2 || [commas count] > 2)
        return NO;
    
    // Only 1 leading zero
    if (points.count == 1 || commas.count == 1) {
        if (range.location == 1 && ![string isEqualToString:@"."] && ![string isEqualToString:@","] && [textField.text isEqualToString:@"0"]) {
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
    
    [self performSelector:@selector(setQRPayment) withObject:nil afterDelay:0.1f];
    
    return YES;
}

#pragma mark - UITableview Delegates

- (void)tableView:(UITableView *)_tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    didClickAccount = (indexPath.section == 0);
    
    if (indexPath.section == 0) {
        int row = (int) indexPath.row;
        detailAddress = [app.wallet getReceiveAddressForAccount:row];
        self.clickedAddress = detailAddress;
        clickedAccount = row;
        
        detailLabel = [app.wallet getLabelForAccount:row];
    }
    else {
        detailAddress = [self getAddress:[_tableView indexPathForSelectedRow]];
        NSString *addr = detailAddress;
        NSString *label = [app.wallet labelForLegacyAddress:addr];
        
        self.clickedAddress = addr;
        
        if (label.length > 0)
            detailLabel = label;
        else
            detailLabel = addr;
    }
    optionsTitleLabel.text = detailLabel;
    
    [self startObservingForReceivedPayment];
    
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
        
        // Show an extra menu item (more actions)
        [app.modalView addSubview:moreActionsButton];
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            moreActionsButton.alpha = 1.0f;
        }];
    }];
    
    [self setQRPayment];
    
    entryField.inputAccessoryView = amountKeyboardAccessoryView;
    
    [self showKeyboard];
    
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
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
    if ([app.wallet getAccountsCount] <= 1 && section == 0) {
        return 12.0f;
    }
    
    return 45.0f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 45)];
    view.backgroundColor = [UIColor whiteColor];
    
    if ([app.wallet getAccountsCount] <= 1 && section == 0) {
        return view;
    }
    
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(20, 20, self.view.frame.size.width, 14)];
    label.textColor = COLOR_FOREGROUND_GRAY;
    label.font = [UIFont systemFontOfSize:14.0];
    
    [view addSubview:label];
    
    NSString *labelString;
    
    if (section == 0)
        labelString = BC_STRING_MY_ACCOUNTS;
    else if (section == 1) {
        labelString = BC_STRING_IMPORTED_ADDRESSES;
        
        UIButton *addButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 20 - 20, 14, 25, 25)];
        [addButton setImage:[UIImage imageNamed:@"new-grey"] forState:UIControlStateNormal];
        [addButton addTarget:self action:@selector(addNewAddressClicked:) forControlEvents:UIControlEventTouchUpInside];
        [view addSubview:addButton];
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
        return [app.wallet getAccountsCount];
    else if (section == 1)
        return [activeKeys count];
    else
        return [archivedKeys count];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    int n = 2;
    
    if ([archivedKeys count]) ++n;
    
    return n;
}

- (UITableViewCell *)tableView:(UITableView *)_tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == 0) {
        int accountIndex = (int) indexPath.row;
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

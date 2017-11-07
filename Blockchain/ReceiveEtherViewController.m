//
//  ReceiveEtherViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/31/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ReceiveEtherViewController.h"
#import "RootService.h"
#import "QRCodeGenerator.h"
#import "UIView+ChangeFrameAttribute.h"
#import "UILabel+Animations.h"

@interface ReceiveEtherViewController ()
@property (nonatomic) QRCodeGenerator *qrCodeGenerator;
@property (nonatomic) UIImageView *qrCodeImageView;
@property (nonatomic) UILabel *addressLabel;
@property (nonatomic) UILabel *instructionsLabel;
@property (nonatomic) NSString *address;
@end

@implementation ReceiveEtherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGFloat statusBarAdjustment = [[UIApplication sharedApplication] statusBarFrame].size.height > DEFAULT_STATUS_BAR_HEIGHT ? DEFAULT_STATUS_BAR_HEIGHT : 0;

    self.view.frame = CGRectMake(0,
                                 TAB_HEADER_HEIGHT_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET - DEFAULT_HEADER_HEIGHT,
                                 [UIScreen mainScreen].bounds.size.width,
                                 [UIScreen mainScreen].bounds.size.height - (TAB_HEADER_HEIGHT_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET) - DEFAULT_FOOTER_HEIGHT - statusBarAdjustment);
    CGFloat imageWidth = IS_USING_SCREEN_SIZE_4S ? 170 : 200;

    UIImageView *qrCodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 120 - 12, imageWidth, imageWidth)];
    qrCodeImageView.center = CGPointMake(self.view.center.x, self.view.frame.size.height/2 - DEFAULT_HEADER_HEIGHT/2);
    [self.view addSubview:qrCodeImageView];
    
    UITapGestureRecognizer *tapMainQRGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainQRClicked)];
    [qrCodeImageView addGestureRecognizer:tapMainQRGestureRecognizer];
    qrCodeImageView.userInteractionEnabled = YES;
    self.qrCodeImageView = qrCodeImageView;

    UILabel *instructionsLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 40, 0)];
    instructionsLabel.textColor = COLOR_TEXT_DARK_GRAY;
    instructionsLabel.textAlignment = NSTextAlignmentCenter;
    instructionsLabel.numberOfLines = 0;
    instructionsLabel.font = [UIFont fontWithName:FONT_GILL_SANS_REGULAR size:FONT_SIZE_SMALL];
    instructionsLabel.text = BC_STRING_RECEIVE_SCREEN_INSTRUCTIONS;
    [instructionsLabel sizeToFit];
    [instructionsLabel changeYPosition:qrCodeImageView.frame.origin.y - instructionsLabel.frame.size.height - 8];
    instructionsLabel.center = CGPointMake(self.view.center.x, instructionsLabel.center.y);
    [self.view addSubview:instructionsLabel];
    self.instructionsLabel = instructionsLabel;
    
    UILabel *addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 40, 40)];
    addressLabel.textColor = COLOR_TEXT_DARK_GRAY;
    addressLabel.textAlignment = NSTextAlignmentCenter;
    addressLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_EXTRA_EXTRA_SMALL];
    [addressLabel changeYPosition:qrCodeImageView.frame.origin.y + qrCodeImageView.frame.size.height];
    addressLabel.center = CGPointMake(self.view.center.x, addressLabel.center.y);
    [self.view addSubview:addressLabel];
    
    UITapGestureRecognizer *tapGestureForAddressLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainQRClicked)];
    [addressLabel addGestureRecognizer:tapGestureForAddressLabel];
    addressLabel.userInteractionEnabled = YES;
    self.addressLabel = addressLabel;
    
    CGFloat spacing = 12;
    CGFloat requestButtonOriginY = self.view.frame.size.height - BUTTON_HEIGHT - spacing;
    UIButton *requestButton = [[UIButton alloc] initWithFrame:CGRectMake(0, requestButtonOriginY, self.view.frame.size.width - 40, BUTTON_HEIGHT)];
    requestButton.center = CGPointMake(self.view.center.x, requestButton.center.y);
    [requestButton setTitle:BC_STRING_REQUEST_PAYMENT forState:UIControlStateNormal];
    requestButton.backgroundColor = COLOR_BLOCKCHAIN_LIGHT_BLUE;
    requestButton.layer.cornerRadius = CORNER_RADIUS_BUTTON;
    requestButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
    [requestButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [requestButton addTarget:self action:@selector(requestButtonClicked) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:requestButton];
}

- (void)reload
{
    [self showEtherAddress];
}

- (void)showEtherAddress
{
    NSString *etherAddress = [app.wallet getEtherAddress];
    self.instructionsLabel.text = etherAddress == nil ? BC_STRING_RECEIVE_ETHER_REENTER_SECOND_PASSWORD_INSTRUCTIONS : BC_STRING_RECEIVE_SCREEN_INSTRUCTIONS;
    self.address = etherAddress;
    self.addressLabel.text = self.address;
    
    self.qrCodeImageView.image = [self.qrCodeGenerator createQRImageFromString:self.address];
}

- (QRCodeGenerator *)qrCodeGenerator
{
    if (!_qrCodeGenerator) {
        _qrCodeGenerator = [[QRCodeGenerator alloc] init];
    }
    return _qrCodeGenerator;
}

- (void)mainQRClicked
{
    [self.addressLabel animateFromText:self.address toIntermediateText:BC_STRING_COPIED_TO_CLIPBOARD speed:1 gestureReceiver:self.addressLabel];
    [UIPasteboard generalPasteboard].string = self.address;
}

- (void)requestButtonClicked
{
    if (![app.wallet isInitialized]) {
        DLog(@"Tried to access share button when not initialized!");
        return;
    }

    NSString *message = [NSString stringWithFormat:BC_STRING_PAYMENT_REQUEST_ETHER_ARGUMENT, self.address];
    
    NSArray *activityItems = @[message, self];
    
    UIActivityViewController *activityViewController = [[UIActivityViewController alloc] initWithActivityItems:activityItems applicationActivities:nil];
    
    activityViewController.excludedActivityTypes = @[UIActivityTypeAssignToContact, UIActivityTypeAddToReadingList, UIActivityTypePostToFacebook];
    
    [activityViewController setValue:BC_STRING_PAYMENT_REQUEST_ETHER_SUBJECT forKey:@"subject"];
    
    [app.tabControllerManager.tabViewController presentViewController:activityViewController animated:YES completion:nil];
}

@end

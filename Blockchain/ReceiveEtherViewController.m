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
@property (nonatomic) UILabel *addressLabel;
@property (nonatomic) NSString *address;
@end

@implementation ReceiveEtherViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSString *etherAddress = [app.wallet getEtherAddress];
    self.address = etherAddress;
    
    CGFloat statusBarAdjustment = [[UIApplication sharedApplication] statusBarFrame].size.height > DEFAULT_STATUS_BAR_HEIGHT ? DEFAULT_STATUS_BAR_HEIGHT : 0;

    self.view.frame = CGRectMake(0,
                                 TAB_HEADER_HEIGHT_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET - DEFAULT_HEADER_HEIGHT,
                                 [UIScreen mainScreen].bounds.size.width,
                                 [UIScreen mainScreen].bounds.size.height - (TAB_HEADER_HEIGHT_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET) - DEFAULT_FOOTER_HEIGHT - statusBarAdjustment);
    CGFloat imageWidth = 120;
    
    UIImageView *qrCodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, self.view.frame.size.height - 120 - 12, imageWidth, imageWidth)];
    qrCodeImageView.center = CGPointMake(self.view.center.x, self.view.frame.size.height/2);
    qrCodeImageView.image = [self.qrCodeGenerator createQRImageFromString:etherAddress];
    [self.view addSubview:qrCodeImageView];
    
    UITapGestureRecognizer *tapMainQRGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainQRClicked)];
    [qrCodeImageView addGestureRecognizer:tapMainQRGestureRecognizer];
    qrCodeImageView.userInteractionEnabled = YES;
    
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
    
    UILabel *addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width - 40, 40)];
    addressLabel.textColor = COLOR_TEXT_DARK_GRAY;
    addressLabel.textAlignment = NSTextAlignmentCenter;
    addressLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_EXTRA_EXTRA_SMALL];
    addressLabel.text = etherAddress;
    [addressLabel changeYPosition:qrCodeImageView.frame.origin.y + qrCodeImageView.frame.size.height];
    addressLabel.center = CGPointMake(self.view.center.x, addressLabel.center.y);
    [self.view addSubview:addressLabel];
    
    UITapGestureRecognizer *tapGestureForAddressLabel = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(mainQRClicked)];
    [addressLabel addGestureRecognizer:tapGestureForAddressLabel];
    addressLabel.userInteractionEnabled = YES;
    self.addressLabel = addressLabel;
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

@end

//
//  BCQRCodeView.m
//  Blockchain
//
//  Created by Kevin Wu on 1/29/16.
//  Copyright © 2016 Qkos Services Ltd. All rights reserved.
//

#import "BCQRCodeView.h"
#import "QRCodeGenerator.h"

const float imageWidth = 190;

@interface BCQRCodeView ()
@property (nonatomic) QRCodeGenerator *qrCodeGenerator;
@end

@implementation BCQRCodeView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self setupWithQRHeaderText:nil];
    }
    
    return self;
}

- (id)initWithFrame:(CGRect)frame qrHeaderText:(NSString *)qrHeaderText
{
    self = [super initWithFrame:frame];
    
    if (self) {
        [self setupWithQRHeaderText:qrHeaderText];
    }
    return self;
}

- (void)setupWithQRHeaderText:(NSString *)qrHeaderText
{
    UILabel *qrCodeHeaderLabel;
    if (qrHeaderText) {
        qrCodeHeaderLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, 15, 280, 60)];
        qrCodeHeaderLabel.font = [UIFont systemFontOfSize:15.0];
        qrCodeHeaderLabel.textColor = [UIColor grayColor];
        qrCodeHeaderLabel.numberOfLines = 5;
        qrCodeHeaderLabel.textAlignment = NSTextAlignmentCenter;
        [qrCodeHeaderLabel adjustFontSizeToFit];
        qrCodeHeaderLabel.text = qrHeaderText;
        [self addSubview:qrCodeHeaderLabel];
    }
    
    CGFloat qrCodeImageViewYPosition = qrCodeHeaderLabel ? qrCodeHeaderLabel.frame.origin.y + qrCodeHeaderLabel.frame.size.height + 15 : 25 ;
    
    self.qrCodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - imageWidth) / 2, qrCodeImageViewYPosition, imageWidth, imageWidth)];
    
    UITapGestureRecognizer *tapMainQRGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(QRCodeClicked)];
    [self.qrCodeImageView addGestureRecognizer:tapMainQRGestureRecognizer];
    self.qrCodeImageView.userInteractionEnabled = YES;
    
    [self addSubview:self.qrCodeImageView];
    
    self.qrCodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.qrCodeImageView.frame.origin.y + self.qrCodeImageView.frame.size.height + 15, 280, 30)];
    self.qrCodeLabel.font = [UIFont systemFontOfSize:17.0];
    self.qrCodeLabel.textAlignment = NSTextAlignmentCenter;
    self.qrCodeLabel.adjustsFontSizeToFitWidth = YES;
    
    [self addSubview:self.qrCodeLabel];
}

- (QRCodeGenerator *)qrCodeGenerator
{
    if (!_qrCodeGenerator) {
        _qrCodeGenerator = [[QRCodeGenerator alloc] init];
    }
    return _qrCodeGenerator;
}

- (void)setAddress:(NSString *)address
{
    _address = address;
    
    self.qrCodeImageView.image = [self.qrCodeGenerator qrImageFromAddress:address];
    self.qrCodeLabel.text = address;
}

- (void)QRCodeClicked
{
    DLog(@"QR Code Clicked!");
}

@end

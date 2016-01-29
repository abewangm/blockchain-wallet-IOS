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
        
        self.qrCodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - imageWidth) / 2, 25, imageWidth, imageWidth)];
        
        UITapGestureRecognizer *tapMainQRGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(QRCodeClicked)];
        [self.qrCodeImageView addGestureRecognizer:tapMainQRGestureRecognizer];
        self.qrCodeImageView.userInteractionEnabled = YES;
        
        [self addSubview:self.qrCodeImageView];
        
        self.qrCodeLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.qrCodeImageView.frame.origin.y + self.qrCodeImageView.frame.size.height + 3, 280, 30)];
        self.qrCodeLabel.font = [UIFont systemFontOfSize:17.0];
        self.qrCodeLabel.textAlignment = NSTextAlignmentCenter;
        self.qrCodeLabel.adjustsFontSizeToFitWidth = YES;
        
        [self addSubview:self.qrCodeLabel];
    }
    return self;
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

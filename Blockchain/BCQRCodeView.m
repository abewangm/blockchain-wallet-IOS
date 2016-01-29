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
        
        self.qrCodeMainImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - imageWidth) / 2, 25, imageWidth, imageWidth)];
        
        UITapGestureRecognizer *tapMainQRGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(QRCodeClicked)];
        [self.qrCodeMainImageView addGestureRecognizer:tapMainQRGestureRecognizer];
        self.qrCodeMainImageView.userInteractionEnabled = YES;
        
        [self addSubview:self.qrCodeMainImageView];
        
        self.qrCodeTextView = [[UITextView alloc] initWithFrame:CGRectMake(20, self.qrCodeMainImageView.frame.origin.y + self.qrCodeMainImageView.frame.size.height + 3, 280, 100)];
        self.qrCodeTextView.editable = NO;
        self.qrCodeTextView.font = [UIFont systemFontOfSize:12.0];
        self.qrCodeTextView.textAlignment = NSTextAlignmentCenter;
        
        [self addSubview:self.qrCodeTextView];
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
    
    self.qrCodeMainImageView.image = [self.qrCodeGenerator qrImageFromAddress:address];
    self.qrCodeTextView.text = address;
}

- (void)QRCodeClicked
{
    DLog(@"QR Code Clicked!");
}

@end

//
//  BCQRCodeView.m
//  Blockchain
//
//  Created by Kevin Wu on 1/29/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
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
        qrCodeHeaderLabel.font = [UIFont fontWithName:FONT_GILL_SANS_REGULAR size:15.0];
        qrCodeHeaderLabel.textColor = COLOR_TEXT_DARK_GRAY;
        qrCodeHeaderLabel.numberOfLines = 5;
        qrCodeHeaderLabel.textAlignment = NSTextAlignmentCenter;
        qrCodeHeaderLabel.text = qrHeaderText;
        [self addSubview:qrCodeHeaderLabel];
    }
    
    CGFloat qrCodeImageViewYPosition = qrCodeHeaderLabel ? qrCodeHeaderLabel.frame.origin.y + qrCodeHeaderLabel.frame.size.height + 15 : 25 ;
    
    self.qrCodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.frame.size.width - imageWidth) / 2, qrCodeImageViewYPosition, imageWidth, imageWidth)];
    [self addSubview:self.qrCodeImageView];
    
    self.qrCodeFooterLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, self.qrCodeImageView.frame.origin.y + self.qrCodeImageView.frame.size.height + 15, 280, 20.5)];
    self.qrCodeFooterLabel.textColor = COLOR_TEXT_DARK_GRAY;
    self.qrCodeFooterLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:17.0];
    self.qrCodeFooterLabel.textAlignment = NSTextAlignmentCenter;
    self.qrCodeFooterLabel.adjustsFontSizeToFitWidth = YES;
    
    UITapGestureRecognizer *tapFooterLabelGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(QRCodeClicked)];
    [self.qrCodeFooterLabel addGestureRecognizer:tapFooterLabelGestureRecognizer];
    self.qrCodeFooterLabel.userInteractionEnabled = YES;
    
    [self addSubview:self.qrCodeFooterLabel];
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
    self.qrCodeFooterLabel.text = address;
}

- (void)QRCodeClicked
{
    [UIPasteboard generalPasteboard].string = self.address;
    [self animateTextOfLabel:self.qrCodeFooterLabel toIntermediateText:BC_STRING_COPIED_TO_CLIPBOARD speed:1 gestureReceiver:self.qrCodeFooterLabel];
}

- (void)animateTextOfLabel:(UILabel *)labelToAnimate toIntermediateText:(NSString *)intermediateText speed:(float)speed gestureReceiver:(UIView *)gestureReceiver
{
    gestureReceiver.userInteractionEnabled = NO;
    
    CGRect originalFrame = labelToAnimate.frame;
    NSString *originalText = labelToAnimate.text;
    UIColor *originalTextColor = labelToAnimate.textColor;
    
    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
        labelToAnimate.alpha = 0.0;
    } completion:^(BOOL finished) {
        
        labelToAnimate.text = intermediateText;
        [labelToAnimate sizeToFit];
        labelToAnimate.center = CGPointMake(self.center.x, labelToAnimate.center.y);
        
        UIImageView *checkImageView = [[UIImageView alloc] initWithFrame:CGRectMake(labelToAnimate.frame.origin.x - labelToAnimate.frame.size.height - 5, labelToAnimate.frame.origin.y, labelToAnimate.frame.size.height, labelToAnimate.frame.size.height)];
        checkImageView.image = [UIImage imageNamed:@"check"];
        checkImageView.image = [checkImageView.image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
        checkImageView.tintColor = COLOR_BUTTON_GREEN;
        [self addSubview:checkImageView];
        checkImageView.alpha = 0.0;
        
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            labelToAnimate.text = intermediateText;
            labelToAnimate.textColor = COLOR_BUTTON_GREEN;
            labelToAnimate.alpha = 1.0;
            checkImageView.alpha = 1.0;
        } completion:^(BOOL finished) {
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(speed * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                    labelToAnimate.alpha = 0.0;
                    checkImageView.alpha = 0.0;
                } completion:^(BOOL finished) {
                    
                    labelToAnimate.frame = originalFrame;
                    
                    [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                        labelToAnimate.text = originalText;
                        labelToAnimate.textColor = originalTextColor;
                        labelToAnimate.alpha = 1.0;
                        gestureReceiver.userInteractionEnabled = YES;
                    } completion:^(BOOL finished) {
                        [checkImageView removeFromSuperview];
                    }];
                }];
            });
        }];
    }];
}


@end

//
//  WebLoginViewController.m
//  Blockchain
//
//  Created by Justin on 2/28/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "RootService.h"
#import "WebLoginViewController.h"
#import "QRCodeGenerator.h"

@interface WebLoginViewController ()
@property (nonatomic) QRCodeGenerator *qrCodeGenerator;
@end

const float qrSize = 180;

@implementation WebLoginViewController

- (id)init {
    if (self = [super init]) {
        self.qrCodeGenerator = [[QRCodeGenerator alloc] init];
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    CGSize size = app.window.frame.size;
    self.view.frame = CGRectMake(0, DEFAULT_HEADER_HEIGHT, size.width, size.height - DEFAULT_HEADER_HEIGHT);

    qrCodeMainImageView = [[UIImageView alloc] initWithFrame:CGRectMake((self.view.frame.size.width - qrSize) / 2, 128, qrSize, qrSize)];
    qrCodeMainImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self.view addSubview:qrCodeMainImageView];

    app.wallet.delegate = self;
    [app.wallet makePairingCode];
}

- (void)didMakePairingCode:(NSString *)code
{
    DLog(@"Made pairing code: %@", code);
    [self setQR:code];
}

- (void)errorMakingPairingCode:(NSString *)message
{
    DLog(@"Error making pairing code: %@", message);
}

- (void)setQR:(NSString *)data
{
    UIImage *qr = [self.qrCodeGenerator createQRImageFromString:data];
    qrCodeMainImageView.image = qr;
    qrCodeMainImageView.contentMode = UIViewContentModeScaleAspectFit;
}

@end

//
//  PairingCodeDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 22/07/2014.
//  Copyright (c) 2014 Blockchain Luxembourg S.A. All rights reserved.
//

#import "PrivateKeyReader.h"
#import "RootService.h"

@implementation PrivateKeyReader

AVCaptureSession *captureSession;
AVCaptureVideoPreviewLayer *videoPreviewLayer;
BOOL isReadingQRCode;

- (id)initWithSuccess:(void (^)(NSString*))__success error:(void (^)(NSString*))__error acceptPublicKeys:(BOOL)acceptPublicKeys busyViewText:(NSString *)text
{
    self = [super init];
    
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        self.success = __success;
        self.error = __error;
        self.acceptsPublicKeys = acceptPublicKeys;
        self.busyViewText = text;
    }
    
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.frame = CGRectMake(0, 0, app.window.frame.size.width, app.window.frame.size.height - DEFAULT_HEADER_HEIGHT);
    
    UIView *topBarView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, DEFAULT_HEADER_HEIGHT)];
    topBarView.backgroundColor = COLOR_BLOCKCHAIN_BLUE;
    [self.view addSubview:topBarView];
    
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(80, 17.5, self.view.frame.size.width - 160, 40)];
    headerLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_TOP_BAR_TEXT];
    headerLabel.textColor = [UIColor whiteColor];
    headerLabel.textAlignment = NSTextAlignmentCenter;
    headerLabel.adjustsFontSizeToFitWidth = YES;
    headerLabel.text = BC_STRING_SCAN_QR_CODE;
    [topBarView addSubview:headerLabel];
    
    UIButton *closeButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80, 15, 80, 51)];
    closeButton.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 20);
    closeButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
    [closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    closeButton.center = CGPointMake(closeButton.center.x, headerLabel.center.y);
    [closeButton addTarget:self action:@selector(closeButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
    [topBarView addSubview:closeButton];
    
    [self startReadingQRCode];
}

- (void)closeButtonClicked:(id)sender
{
    [self stopReadingQRCode];
}

- (void)startReadingQRCode
{
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        // This should never happen - all devices we support (iOS 7+) have cameras
        DLog(@"QR code scanner problem: %@", [error localizedDescription]);
        return;
    }
    
    captureSession = [[AVCaptureSession alloc] init];
    [captureSession addInput:input];
    
    AVCaptureMetadataOutput *captureMetadataOutput = [[AVCaptureMetadataOutput alloc] init];
    [captureSession addOutput:captureMetadataOutput];
    
    dispatch_queue_t dispatchQueue;
    dispatchQueue = dispatch_queue_create("myQueue", NULL);
    [captureMetadataOutput setMetadataObjectsDelegate:self queue:dispatchQueue];
    [captureMetadataOutput setMetadataObjectTypes:[NSArray arrayWithObject:AVMetadataObjectTypeQRCode]];
    
    videoPreviewLayer = [[AVCaptureVideoPreviewLayer alloc] initWithSession:captureSession];
    [videoPreviewLayer setVideoGravity:AVLayerVideoGravityResizeAspectFill];
    
    CGRect frame = CGRectMake(0, DEFAULT_HEADER_HEIGHT, app.window.frame.size.width, app.window.frame.size.height - DEFAULT_HEADER_HEIGHT);
    
    [videoPreviewLayer setFrame:frame];
    
    [self.view.layer addSublayer:videoPreviewLayer];
    
    [captureSession startRunning];
}

- (void)stopReadingQRCode
{
    [captureSession stopRunning];
    captureSession = nil;
    
    [videoPreviewLayer removeFromSuperlayer];
    
    [self dismissViewControllerAnimated:YES completion:nil];
    
    if (self.error) {
        self.error(nil);
    }
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            // Close the QR code reader
            dispatch_sync(dispatch_get_main_queue(), ^{
                [self stopReadingQRCode];
                
                [app showBusyViewWithLoadingText:self.busyViewText];
            });
            
            // Check the format of the privateKey and if it's valid, pass it back via the success callback
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                NSString *scannedString = [metadataObj stringValue];
                
                if ([scannedString hasPrefix:PREFIX_BITCOIN_URI]) {
                    scannedString = [scannedString substringFromIndex:[PREFIX_BITCOIN_URI length]];
                }
                 
                NSString *format = [app.wallet detectPrivateKeyFormat:scannedString];
                
                if (!app.wallet || [format length] > 0) {
                    if (self.success) {
                        self.success(scannedString);
                    }
                } else {
                    [app hideBusyView];
                    
                    if (self.acceptsPublicKeys) {
                        if ([app.wallet isBitcoinAddress:scannedString]) {
                            [app askUserToAddWatchOnlyAddress:scannedString success:self.success];
                        } else {
                            [app standardNotifyAutoDismissingController:BC_STRING_UNKNOWN_KEY_FORMAT];
                        }
                    } else {
                        [app standardNotifyAutoDismissingController:BC_STRING_UNSUPPORTED_PRIVATE_KEY_FORMAT];
                    }
                }
            });
        }
    }
}

@end

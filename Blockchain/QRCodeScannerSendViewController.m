//
//  QRCodeScannerSendViewController.m
//  Blockchain
//
//  Created by kevinwu on 9/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "QRCodeScannerSendViewController.h"
#import <AVFoundation/AVFoundation.h>
#import "RootService.h"

@interface QRCodeScannerSendViewController () <AVCaptureMetadataOutputObjectsDelegate>

@end

AVCaptureSession *captureSession;
AVCaptureVideoPreviewLayer *videoPreviewLayer;

@implementation QRCodeScannerSendViewController

- (IBAction)QRCodebuttonClicked:(id)sender
{
    if (!captureSession) {
        [self startReadingQRCode];
    }
}

- (BOOL)startReadingQRCode
{
    AVCaptureDeviceInput *input = [app getCaptureDeviceInput:nil];
    
    if (!input) {
        return NO;
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
    
    CGRect frame = CGRectMake(0, 0, WINDOW_WIDTH, WINDOW_HEIGHT);
    
    [videoPreviewLayer setFrame:frame];
    
    UIView *view = [[UIView alloc] initWithFrame:frame];
    [view.layer addSublayer:videoPreviewLayer];
    
    [app showModalWithContent:view closeType:ModalCloseTypeClose headerText:BC_STRING_SCAN_QR_CODE onDismiss:^{
        [captureSession stopRunning];
        captureSession = nil;
        [videoPreviewLayer removeFromSuperlayer];
    } onResume:nil];
    
    [captureSession startRunning];
    
    return YES;
}

- (void)stopReadingQRCode
{
    [app closeModalWithTransition:kCATransitionFade];
    
    // Go to the send scren if we are not already on it
    [app showSendCoins];
}

@end

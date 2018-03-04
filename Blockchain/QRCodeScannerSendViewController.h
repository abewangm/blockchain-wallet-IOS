//
//  QRCodeScannerSendViewController.h
//  Blockchain
//
//  Created by kevinwu on 9/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

@interface QRCodeScannerSendViewController : UIViewController
@property (nonatomic) AVCaptureSession *captureSession;
@property (nonatomic) AVCaptureVideoPreviewLayer *videoPreviewLayer;
- (IBAction)QRCodebuttonClicked:(id)sender;
@end

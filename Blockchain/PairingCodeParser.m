//
//  PairingCodeDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 22/07/2014.
//  Copyright (c) 2014 Blockchain Luxembourg S.A. All rights reserved.
//

#import "PairingCodeParser.h"
#import "RootService.h"

@implementation PairingCodeParser

AVCaptureSession *captureSession;
AVCaptureVideoPreviewLayer *videoPreviewLayer;
BOOL isReadingQRCode;

- (id)initWithSuccess:(void (^)(NSDictionary*))__success error:(void (^)(NSString*))__error
{
    self = [super init];
    
    if (self) {
        self.modalTransitionStyle = UIModalTransitionStyleCrossDissolve;
        
        self.success = __success;
        self.error = __error;
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
    headerLabel.text = BC_STRING_SCAN_PAIRING_CODE;
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
    
    [videoPreviewLayer removeFromSuperlayer];
    [self dismissViewControllerAnimated:YES completion:nil];
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
}

- (void)captureOutput:(AVCaptureOutput *)captureOutput didOutputMetadataObjects:(NSArray *)metadataObjects fromConnection:(AVCaptureConnection *)connection{
    if (metadataObjects != nil && [metadataObjects count] > 0) {
        AVMetadataMachineReadableCodeObject *metadataObj = [metadataObjects objectAtIndex:0];
        if ([[metadataObj type] isEqualToString:AVMetadataObjectTypeQRCode]) {
            // do something useful with results
            [self stopReadingQRCode];
            
            dispatch_sync(dispatch_get_main_queue(), ^{
                
                [videoPreviewLayer removeFromSuperlayer];
                
                [self dismissViewControllerAnimated:YES completion:nil];

                [app showBusyViewWithLoadingText:BC_STRING_PARSING_PAIRING_CODE];
                
            });
            
            [app.wallet loadBlankWallet];
            
            app.wallet.delegate = self;
            
            [app.wallet parsePairingCode:[metadataObj stringValue]];
        }
    }
}

- (void)errorParsingPairingCode:(NSString *)message
{
    [app hideBusyView];

    if (self.error) {
        if ([message containsString:ERROR_INVALID_PAIRING_VERSION_CODE]) {
            self.error(BC_STRING_INVALID_PAIRING_CODE);
        } else if ([message containsString:ERROR_TYPE_MUST_START_WITH_NUMBER] || [message containsString:ERROR_FIRST_ARGUMENT_MUST_BE_STRING]){
            self.error(BC_STRING_ERROR_PLEASE_REFRESH_PAIRING_CODE);
        } else {
            self.error(message);
        }
    }
}

-(void)didParsePairingCode:(NSDictionary *)dict
{
    [app hideBusyView];

    if (self.success) {
        self.success(dict);
    }
}

@end

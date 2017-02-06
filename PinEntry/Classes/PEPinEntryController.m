/********************************************************************************
*                                                                               *
* Copyright (c) 2010 Vladimir "Farcaller" Pouzanov <farcaller@gmail.com>        *
*                                                                               *
* Permission is hereby granted, free of charge, to any person obtaining a copy  *
* of this software and associated documentation files (the "Software"), to deal *
* in the Software without restriction, including without limitation the rights  *
* to use, copy, modify, merge, publish, distribute, sublicense, and/or sell     *
* copies of the Software, and to permit persons to whom the Software is         *
* furnished to do so, subject to the following conditions:                      *
*                                                                               *
* The above copyright notice and this permission notice shall be included in    *
* all copies or substantial portions of the Software.                           *
*                                                                               *
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR    *
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,      *
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE   *
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER        *
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, *
* OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN     *
* THE SOFTWARE.                                                                 *
*                                                                               *
********************************************************************************/

#import "PEPinEntryController.h"
#import "QRCodeGenerator.h"
#import "RootService.h"
#import "KeychainItemWrapper+SwipeAddresses.h"

#define PS_VERIFY	0
#define PS_ENTER1	1
#define PS_ENTER2	2

static PEViewController *EnterController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = BC_STRING_PLEASE_ENTER_PIN;
	c.title = @"";

    c.versionLabel.text = [app getVersionLabelString];
    
	return c;
}

static PEViewController *NewController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = BC_STRING_PLEASE_ENTER_NEW_PIN;
	c.title = @"";

    c.versionLabel.text = [app getVersionLabelString];

    return c;
}

static PEViewController *VerifyController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = BC_STRING_CONFIRM_PIN;
	c.title = @"";

    c.versionLabel.text = [app getVersionLabelString];

	return c;
}

@implementation PEPinEntryController

@synthesize pinDelegate, verifyOnly, verifyOptional, inSettings;

+ (PEPinEntryController *)pinVerifyController
{
	PEViewController *c = EnterController();
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
    n->pinController = c;
	n->pinStage = PS_VERIFY;
	n->verifyOnly = YES;
	return n;
}

+ (PEPinEntryController *)pinVerifyControllerClosable
{
    PEViewController *c = EnterController();
    PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
    c.delegate = n;
    [c.cancelButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
    c.cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    c.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:BC_STRING_CANCEL style:UIBarButtonItemStylePlain target:n action:@selector(cancelController)];
    n->pinController = c;
    n->pinStage = PS_VERIFY;
    n->verifyOptional = YES;
    n->inSettings = YES;
    return n;
}

+ (PEPinEntryController *)pinChangeController
{
	PEViewController *c = EnterController();
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
    [c.cancelButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
    c.cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    c.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:BC_STRING_CANCEL style:UIBarButtonItemStylePlain target:n action:@selector(cancelController)];
    n->pinController = c;
	n->pinStage = PS_VERIFY;
	n->verifyOnly = NO;
    n->inSettings = YES;
	return n;
}

+ (PEPinEntryController *)pinCreateController
{
	PEViewController *c = NewController();
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
    n->pinController = c;
	n->pinStage = PS_ENTER1;
	n->verifyOnly = NO;
	return n;
}

- (void)reset
{
    [pinController resetPin];
}

- (void)setupQRCode
{
#ifdef ENABLE_SWIPE_TO_RECEIVE
    if (self.verifyOnly &&
        [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_SWIPE_TO_RECEIVE_ENABLED] &&
        [KeychainItemWrapper getSwipeAddresses]) {
        
        pinController.swipeLabel.alpha = 1;
        pinController.swipeLabel.hidden = NO;
        
        pinController.swipeLabelImageView.alpha = 1;
        pinController.swipeLabelImageView.hidden = NO;
        
        [pinController.scrollView setContentSize:CGSizeMake(pinController.scrollView.frame.size.width *2, pinController.scrollView.frame.size.height)];
        [pinController.scrollView setPagingEnabled:YES];
        pinController.scrollView.delegate = self;
        
        [pinController.scrollView setUserInteractionEnabled:YES];
        
        if (!self.addressLabel) {
            self.addressLabel = [[UILabel alloc] initWithFrame:CGRectMake(320, 260, 320, 30)];
            [self.addressLabel setTextAlignment:NSTextAlignmentCenter];
            [self.addressLabel setTextColor:[UIColor whiteColor]];
            [self.addressLabel setFont:[UIFont systemFontOfSize:12]];
            self.addressLabel.adjustsFontSizeToFitWidth = YES;
            [pinController.scrollView addSubview:self.addressLabel];
        }
        
        NSString *nextAddress = [[KeychainItemWrapper getSwipeAddresses] firstObject];
        
        if (nextAddress) {
            
            void (^error)() = ^() {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_NO_INTERNET_CONNECTION message:BC_STRING_SWIPE_TO_RECEIVE_NO_INTERNET_CONNECTION_WARNING preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
                    self.qrCodeImageView.hidden = YES;
                    self.addressLabel.text = BC_STRING_REQUEST_FAILED_PLEASE_CHECK_INTERNET_CONNECTION;
                }]];
                [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                    [app.wallet subscribeToSwipeAddress:nextAddress];
                    
                    if (!self.qrCodeImageView) {
                        self.qrCodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width + 40, 20, self.view.frame.size.width - 80, self.view.frame.size.width - 80)];
                        [pinController.scrollView addSubview:self.qrCodeImageView];
                    }
                    
                    QRCodeGenerator *qrCodeGenerator = [[QRCodeGenerator alloc] init];
                    
                    self.qrCodeImageView.hidden = NO;
                    self.qrCodeImageView.image = [qrCodeGenerator qrImageFromAddress:nextAddress];
                    self.addressLabel.text = nextAddress;
                }]];
                self.errorAlert = alert;
            };

            void (^success)(NSString *, BOOL) = ^(NSString *address, BOOL isUnused) {
                
                if (isUnused) {
                    [app.wallet subscribeToSwipeAddress:nextAddress];
                    
                    if (!self.qrCodeImageView) {
                        self.qrCodeImageView = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width + 40, 20, self.view.frame.size.width - 80, self.view.frame.size.width - 80)];
                        [pinController.scrollView addSubview:self.qrCodeImageView];
                    }
                    
                    QRCodeGenerator *qrCodeGenerator = [[QRCodeGenerator alloc] init];
                    
                    self.qrCodeImageView.hidden = NO;
                    self.qrCodeImageView.image = [qrCodeGenerator qrImageFromAddress:nextAddress];
                    self.addressLabel.text = nextAddress;
                    self.errorAlert = nil;
                } else {
                    [KeychainItemWrapper removeFirstSwipeAddress];
                    [self setupQRCode];
                    self.errorAlert = nil;
                }
            };
            
            [app checkForUnusedAddress:nextAddress success:success error:error];

        } else {
            self.qrCodeImageView.hidden = YES;
            self.addressLabel.text = BC_STRING_PLEASE_LOGIN_TO_LOAD_MORE_ADDRESSES;
        }
    } else {
        pinController.swipeLabel.hidden = YES;
        pinController.swipeLabelImageView.hidden = YES;
    }
#else
    pinController.swipeLabel.hidden = YES;
    pinController.swipeLabelImageView.hidden = YES;
#endif
}

- (void)paymentReceived
{
    if ([KeychainItemWrapper getSwipeAddresses].count > 0) {
        [KeychainItemWrapper removeFirstSwipeAddress];
        [self setupQRCode];
    } else {
        [self.qrCodeImageView removeFromSuperview];
        self.addressLabel.text = BC_STRING_PLEASE_LOGIN_TO_LOAD_MORE_ADDRESSES;
    }
}

- (void)pinEntryControllerDidEnteredPin:(PEViewController *)controller
{
	switch (pinStage) {
		case PS_VERIFY: {
			[self.pinDelegate pinEntryController:self shouldAcceptPin:[controller.pin intValue] callback:^(BOOL yes) {
                if (yes) {
                    if(verifyOnly == NO) {
                        PEViewController *c = NewController();
                        c.delegate = self;
                        pinStage = PS_ENTER1;
                        [[self navigationController] pushViewController:c animated:NO];
                        self.viewControllers = [NSArray arrayWithObject:c];
                    }
                } else {
                    controller.prompt = BC_STRING_INCORRECT_PIN_RETRY;
                    [controller resetPin];
                }
            }];
			break;
        }
		case PS_ENTER1: {
			pinEntry1 = [controller.pin intValue];
			PEViewController *c = VerifyController();
			c.delegate = self;
			[[self navigationController] pushViewController:c animated:NO];
			self.viewControllers = [NSArray arrayWithObject:c];
			pinStage = PS_ENTER2;
            [self.pinDelegate pinEntryController:self willChangeToNewPin:[controller.pin intValue]];
			break;
		}
		case PS_ENTER2:
			if([controller.pin intValue] != pinEntry1) {
                UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:BC_PIN_NO_MATCH preferredStyle:UIAlertControllerStyleAlert];
                [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
				PEViewController *c = NewController();
				c.delegate = self;
				self.viewControllers = [NSArray arrayWithObjects:c, [self.viewControllers objectAtIndex:0], nil];
				[self popViewControllerAnimated:NO];
                [self presentViewController:alert animated:YES completion:nil];
			} else {
				[self.pinDelegate pinEntryController:self changedPin:[controller.pin intValue]];
			}
			break;
		default:
			break;
	}
}

- (UIViewController *)popViewControllerAnimated:(BOOL)animated
{
	pinStage = PS_ENTER1;
	return [super popViewControllerAnimated:animated];
}

- (void)cancelController
{
	[self.pinDelegate pinEntryControllerDidCancel:self];
}

#pragma mark Debug Menu

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
#ifdef ENABLE_DEBUG_MENU
    if (self.verifyOnly) {
        self.longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
        self.longPressGesture.minimumPressDuration = DURATION_LONG_PRESS_GESTURE_DEBUG;
        self.debugButton = [[UIButton alloc] initWithFrame:CGRectMake(self.view.frame.size.width - 80, 15, 80, 51)];
        self.debugButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        self.debugButton.titleLabel.adjustsFontSizeToFitWidth = YES;
        [self.debugButton setTitleEdgeInsets:UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)];
        [self.debugButton setTitle:DEBUG_STRING_DEBUG forState:UIControlStateNormal];
        [self.view addSubview:self.debugButton];
        [self.debugButton addGestureRecognizer:self.longPressGesture];
    }
#endif
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    self.longPressGesture = nil;
    [self.debugButton removeFromSuperview];
}

- (void)handleLongPress:(UILongPressGestureRecognizer *)longPress
{
    if (longPress.state == UIGestureRecognizerStateBegan) {
        [app showDebugMenu:DEBUG_PRESENTER_PIN_VERIFY];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    if (scrollView.contentOffset.x > 0 && self.errorAlert) {
        [self presentViewController:self.errorAlert animated:YES completion:nil];
        self.errorAlert = nil;
    }
}

@end

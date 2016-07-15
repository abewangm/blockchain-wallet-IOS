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
#import "AppDelegate.h"

#define PS_VERIFY	0
#define PS_ENTER1	1
#define PS_ENTER2	2

static NSString *getVersionLabelString()
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    NSString *build = infoDictionary[@"CFBundleVersion"];
    NSString *versionAndBuild = [NSString stringWithFormat:@"%@ b%@", version, build];
    return[NSString stringWithFormat:@"%@", versionAndBuild];
}

static PEViewController *EnterController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = BC_STRING_PLEASE_ENTER_PIN;
	c.title = @"";

    c.versionLabel.text = getVersionLabelString();
    
	return c;
}

static PEViewController *NewController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = BC_STRING_PLEASE_ENTER_NEW_PIN;
	c.title = @"";

    c.versionLabel.text = getVersionLabelString();

    return c;
}

static PEViewController *VerifyController()
{
	PEViewController *c = [[PEViewController alloc] init];
	c.prompt = BC_STRING_CONFIRM_PIN;
	c.title = @"";

    c.versionLabel.text = getVersionLabelString();

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
                UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_ERROR message:BC_PIN_NO_MATCH delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles:nil];
                [alertView show];
				PEViewController *c = NewController();
				c.delegate = self;
				self.viewControllers = [NSArray arrayWithObjects:c, [self.viewControllers objectAtIndex:0], nil];
				[self popViewControllerAnimated:NO];
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
        [self.debugButton setTitle:BC_STRING_DEBUG forState:UIControlStateNormal];
        [self.view addSubview:self.debugButton];
        [self.debugButton addGestureRecognizer:self.longPressGesture];
    }
#endif
#ifdef ENABLE_SWIPE_TO_RECEIVE
    if (self.verifyOnly) {
        
        [pinController.scrollView setUserInteractionEnabled:YES];
        
        NSString *nextAddress = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_NEXT_ADDRESS];
        NSNumber *nextAddressUsed = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_NEXT_ADDRESS_USED];
        
        if (nextAddress) {
            
            pinController.swipeLabel.alpha = 1;
            pinController.swipeLabel.hidden = NO;
            
            [pinController.scrollView setContentSize:CGSizeMake(pinController.scrollView.frame.size.width *2, pinController.scrollView.frame.size.height)];
            [pinController.scrollView setPagingEnabled:YES];
            
            [app.wallet subscribeToAddress:nextAddress];
            
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                [UIView animateWithDuration:.5 animations:^{
                    pinController.swipeLabel.alpha = 0;
                }];
            });
            
            UILabel *descLabel = [[UILabel alloc] initWithFrame:CGRectMake(320, 260, 320, 30)];
            [descLabel setTextAlignment:NSTextAlignmentCenter];
            [descLabel setTextColor:[UIColor whiteColor]];
            [descLabel setFont:[UIFont systemFontOfSize:12]];
            
            if (![nextAddressUsed boolValue]) {
                QRCodeGenerator *qrCodeGenerator = [[QRCodeGenerator alloc] init];
                
                UIImageView *qr = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.frame.size.width + 40, 20, self.view.frame.size.width - 80, self.view.frame.size.width - 80)];
                qr.image = [qrCodeGenerator qrImageFromAddress:nextAddress];
                descLabel.text = nextAddress;
                
                [pinController.scrollView addSubview:qr];
            } else {
                descLabel.text = BC_STRING_ADDRESS_ALREADY_USED_PLEASE_LOGIN;
            }
            
            [pinController.scrollView addSubview:descLabel];
        } else {
            pinController.swipeLabel.hidden = YES;
        }
    }
#else
    pinController.swipeLabel.hidden = YES;
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

@end

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

#define PS_VERIFY	0
#define PS_ENTER1	1
#define PS_ENTER2	2

static NSString *getVersionLabelString()
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle]infoDictionary];
    NSString *version = infoDictionary[@"CFBundleShortVersionString"];
    NSString *build = infoDictionary[@"CFBundleVersion"];
    NSString *versionAndBuild = [NSString stringWithFormat:@"%@ b%@", version, build];
#ifdef DEBUG
    #ifdef HD_ENABLED
        return [NSString stringWithFormat:@"%@ (v3)", versionAndBuild];
    #else
        return [NSString stringWithFormat:@"%@ (v2)", versionAndBuild];
    #endif
#else
    return[NSString stringWithFormat:@"%@", versionAndBuild];
#endif
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

@synthesize pinDelegate, verifyOnly, verifyOptional;

+ (PEPinEntryController *)pinVerifyController
{
	PEViewController *c = EnterController();
    [[self class] addLongPressGestureToVersionLabel:c.versionLabel];
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
    [[self class] addLongPressGestureToVersionLabel:c.versionLabel];
    PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
    c.delegate = n;
    [c.cancelButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
    c.cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    c.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:BC_STRING_CANCEL style:UIBarButtonItemStylePlain target:n action:@selector(cancelController)];
    n->pinController = c;
    n->pinStage = PS_VERIFY;
    n->verifyOptional = YES;
    return n;
}

+ (PEPinEntryController *)pinChangeController
{
	PEViewController *c = EnterController();
    [[self class] addLongPressGestureToVersionLabel:c.versionLabel];
	PEPinEntryController *n = [[self alloc] initWithRootViewController:c];
	c.delegate = n;
    [c.cancelButton setTitle:BC_STRING_CLOSE forState:UIControlStateNormal];
    c.cancelButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    c.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:BC_STRING_CANCEL style:UIBarButtonItemStylePlain target:n action:@selector(cancelController)];
    n->pinController = c;
	n->pinStage = PS_VERIFY;
	n->verifyOnly = NO;
	return n;
}

+ (PEPinEntryController *)pinCreateController
{
	PEViewController *c = NewController();
    [[self class] addLongPressGestureToVersionLabel:c.versionLabel];
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
                        [[self class] addLongPressGestureToVersionLabel:c.versionLabel];
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
            [[self class] addLongPressGestureToVersionLabel:c.versionLabel];
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

+ (void)addLongPressGestureToVersionLabel:(UILabel *)versionLabel
{
    UILongPressGestureRecognizer *longPressGesture = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleLongPress:)];
    longPressGesture.minimumPressDuration = 1.0;
    [versionLabel addGestureRecognizer:longPressGesture];
    versionLabel.userInteractionEnabled = YES;
}

+ (void)showBundleShortNameAlert
{
    NSDictionary *infoDictionary = [[NSBundle mainBundle] infoDictionary];
    NSString *bundleShortName = infoDictionary[@"CFBundleName"];
    NSString *bundleVersion = infoDictionary[@"CFBundleVersion"];
    NSString *bundleShortVersionString = infoDictionary[@"CFBundleShortVersionString"];
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:bundleShortName message:[[NSString alloc] initWithFormat:@"Build %@\nv%@", bundleVersion, bundleShortVersionString] delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
    [alert show];
}

+  (void)handleLongPress:(UILongPressGestureRecognizer*)sender
{
    if (sender.state == UIGestureRecognizerStateBegan){
        [self showBundleShortNameAlert];
    }
}

@end

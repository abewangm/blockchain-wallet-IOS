//
//  AppDelegate.m
//  Blockchain
//
//  Created by Ben Reeves on 05/01/2012.
//  Copyright (c) 2012 Qkos Services Ltd. All rights reserved.
//
#import <QuartzCore/QuartzCore.h>

#import "AppDelegate.h"
#import "MultiAddressResponse.h"
#import "Wallet.h"
#import "BCFadeView.h"
#import "TabViewController.h"
#import "ReceiveCoinsViewController.h"
#import "SendViewController.h"
#import "TransactionsViewController.h"
#import "BCCreateWalletView.h"
#import "BCManualPairView.h"
#import "NSString+SHA256.h"
#import "Transaction.h"
#import "UIDevice+Hardware.h"
#import "UncaughtExceptionHandler.h"
#import "UITextField+Blocks.h"
#import "UIAlertView+Blocks.h"
#import "PairingCodeParser.h"
#import "PrivateKeyReader.h"
#import "MerchantMapViewController.h"
#import "NSData+Hex.h"
#import "Reachability.h"
#import "SideMenuViewController.h"
#import "BCWelcomeView.h"
#import "BCHdUpgradeView.h"
#import "BCWebViewController.h"
#import "KeychainItemWrapper.h"
#import "UpgradeViewController.h"
#import <LocalAuthentication/LocalAuthentication.h>
#import "UIViewController+AutoDismiss.h"
#import "DeviceIdentifier.h"
#import "DebugTableViewController.h"

AppDelegate * app;

@implementation AppDelegate

@synthesize window = _window;
@synthesize wallet;
@synthesize modalView;
@synthesize latestResponse;

BOOL showSendCoins = NO;

SideMenuViewController *sideMenuViewController;
UIImageView *curtainImageView;


void (^addPrivateKeySuccess)(NSString *);
void (^secondPasswordSuccess)(NSString *);

#pragma mark - Lifecycle

- (id)init
{
    if (self = [super init]) {
        [self setupBtcFormatter];
        [self setupLocalCurrencyFormatter];
        
        self.modalChain = [[NSMutableArray alloc] init];
                
        app = self;
    }
    
    return self;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    [self checkForNewInstall];
    
    [self persistServerSessionIDForNewUIWebViews];
    
    [self disableUIWebViewCaching];
    
    // Allocate the global wallet
    self.wallet = [[Wallet alloc] init];
    self.wallet.delegate = self;
    
    // Send email when exceptions are caught
#ifndef DEBUG
    NSSetUncaughtExceptionHandler(&HandleException);
#endif
    
#ifndef ENABLE_DEBUG_MENU
    // DLog(@"Clearing debug menu userDefaults since debug menu is off");
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_DEBUG_MERCHANT_URL];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_DEBUG_API_URL];
    [[NSUserDefaults standardUserDefaults] synchronize];
#endif
    
    // White status bar
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:NOTIFICATION_KEY_LOADING_TEXT object:nil queue:nil usingBlock:^(NSNotification * notification) {
        self.loadingText = [notification object];
    }];
    
    _window.backgroundColor = [UIColor whiteColor];
    
    [self setupSideMenu];
    
    [_window makeKeyAndVisible];
    
    // Default view in TabViewController: transactionsViewController
    [_tabViewController setActiveViewController:_transactionsViewController];
    [_window.rootViewController.view addSubview:busyView];
    
    busyView.frame = _window.frame;
    busyView.alpha = 0.0f;
    
    // Load settings    
    symbolLocal = [[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_SYMBOL_LOCAL];

    [self showWelcomeOrPinScreen];
        
    return YES;
}

- (void)transitionToIndex:(NSInteger)newIndex
{
    if (newIndex == 0)
        [self sendCoinsClicked:nil];
    else if (newIndex == 1)
        [self transactionsClicked:nil];
    else if (newIndex == 2)
        [self receiveCoinClicked:nil];
}

- (void)swipeLeft
{
    if (_tabViewController.selectedIndex < 2)
    {
        NSInteger newIndex = _tabViewController.selectedIndex + 1;
        [self transitionToIndex:newIndex];
    }
}

- (void)swipeRight
{
    if (_tabViewController.selectedIndex)
    {
        NSInteger newIndex = _tabViewController.selectedIndex - 1;
        [self transitionToIndex:newIndex];
    }
}

#pragma mark - Setup

- (void)setupBtcFormatter
{
    self.btcFormatter = [[NSNumberFormatter alloc] init];
    [_btcFormatter setMaximumFractionDigits:8];
    [_btcFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
}

- (void)setupLocalCurrencyFormatter
{
    self.localCurrencyFormatter = [[NSNumberFormatter alloc] init];
    [_localCurrencyFormatter setMinimumFractionDigits:2];
    [_localCurrencyFormatter setMaximumFractionDigits:2];
    [_localCurrencyFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
}

- (void)persistServerSessionIDForNewUIWebViews
{
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
}

- (void)disableUIWebViewCaching
{
    NSURLCache *sharedCache = [[NSURLCache alloc] initWithMemoryCapacity:0 diskCapacity:0 diskPath:nil];
    [NSURLCache setSharedURLCache:sharedCache];
}

- (void)setupSideMenu
{
    _slidingViewController = [[ECSlidingViewController alloc] init];
    _slidingViewController.topViewController = _tabViewController;
    sideMenuViewController = [[SideMenuViewController alloc] init];
    _slidingViewController.underLeftViewController = sideMenuViewController;
    _window.rootViewController = _slidingViewController;
}

- (void)showWelcomeOrPinScreen
{
    // Not paired yet
    if (![self guid] || ![self sharedKey]) {
        [self showWelcome];
        [self checkAndWarnOnJailbrokenPhones];
    }
    // Paired
    else {

        // If the PIN is set show the pin modal
        if ([self isPinSet]) {
            [self showPinModalAsView:YES];
#ifdef TOUCH_ID_ENABLED
            if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED]) {
                [self authenticateWithTouchID];
            }
#endif
        } else {
            // No PIN set we need to ask for the main password
            [self showPasswordModal];
            [self checkAndWarnOnJailbrokenPhones];
        }
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reloadSideMenu) name:NOTIFICATION_KEY_GET_ACCOUNT_INFO_SUCCESS object:nil];
        
        [self migratePasswordAndPinFromNSUserDefaults];
    }
    
    // TODO create BCCurtainView. There shouldn't be any view code, etc in the appdelegate..
    [self setupCurtainView];
}

- (void)migratePasswordAndPinFromNSUserDefaults
{
    NSString * password = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_PASSWORD];
    NSString * pin = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_PIN];
    
    if (password && pin) {
        self.wallet.password = password;
        
        [self savePIN:pin];
        
        // TODO only remove these if savePIN is successful (required JS modifications) (and synchronize)
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_PASSWORD];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_PIN];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}

- (void)setupCurtainView
{
    // Curtain view setup
    curtainImageView = [[UIImageView alloc] initWithFrame:self.window.bounds];
    
    // Select the correct image depending on the screen size. The names used are the default names that LaunchImage assets get after processing. See @http://stackoverflow.com/questions/19107543/xcode-5-asset-catalog-how-to-reference-the-launchimage
    // This works for iPhone 4/4S, 5/5S, 6 and 6Plus in Portrait
    // TODO need to add new screen sizes with new iPhones ... ugly
    // TODO we're currently using the scaled version of the app on iPhone 6 and 6 Plus
    //        NSDictionary *dict = @{@"320x480" : @"LaunchImage-700", @"320x568" : @"LaunchImage-700-568h", @"375x667" : @"LaunchImage-800-667h", @"414x736" : @"LaunchImage-800-Portrait-736h"};
    NSDictionary *dict = @{@"320x480" : @"LaunchImage-700", @"320x568" : @"LaunchImage-700-568h", @"375x667" : @"LaunchImage-700-568h", @"414x736" : @"LaunchImage-700-568h"};
    NSString *key = [NSString stringWithFormat:@"%dx%d", (int)[UIScreen mainScreen].bounds.size.width, (int)[UIScreen mainScreen].bounds.size.height];
    UIImage *launchImage = [UIImage imageNamed:dict[key]];
    
    curtainImageView.image = launchImage;
    curtainImageView.alpha = 0;
}

#pragma mark - UI State

- (void)reload
{
    [_sendViewController reload];
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_settingsNavigationController reload];
    [_accountsAndAddressesNavigationController reload];
    
    [sideMenuViewController reload];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    // Legacy code for generating new addresses
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_NEW_ADDRESS object:nil userInfo:nil];
}

- (void)reloadAfterMultiAddressResponse
{
    [_sendViewController reloadAfterMultiAddressResponse];
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_settingsNavigationController reload];
    [_accountsAndAddressesNavigationController reload];
    
    [sideMenuViewController reload];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    // Legacy code for generating new addresses
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_NEW_ADDRESS object:nil userInfo:nil];
}

- (void)reloadSideMenu
{
    [sideMenuViewController reloadTableView];
}

- (void)toggleSymbol
{
    symbolLocal = !symbolLocal;
    
    // Save this setting here and load it on start
    [[NSUserDefaults standardUserDefaults] setBool:symbolLocal forKey:USER_DEFAULTS_KEY_SYMBOL_LOCAL];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self reloadTopLevelViewControllers];
}

- (NSInteger)filterIndex
{
    return _transactionsViewController.filterIndex;
}

- (void)filterTransactionsByAccount:(int)accountIndex
{
    _transactionsViewController.clickedFetchMore = NO;
    _transactionsViewController.filterIndex = accountIndex;
    [_transactionsViewController changeFilterLabel:[app.wallet getLabelForAccount:accountIndex]];
    [_transactionsViewController showFilterLabel];
    self.mainLogoImageView.hidden = YES;
    
    [self.wallet reloadFilter];
    
    [self showFilterResults];
}

- (void)filterTransactionsByImportedAddresses
{
    _transactionsViewController.clickedFetchMore = NO;
    _transactionsViewController.filterIndex = FILTER_INDEX_IMPORTED_ADDRESSES;
    [_transactionsViewController changeFilterLabel:BC_STRING_IMPORTED_ADDRESSES];
    [_transactionsViewController showFilterLabel];
    self.mainLogoImageView.hidden = YES;
    
    [self.wallet reloadFilter];
    
    [self showFilterResults];
}

- (void)removeTransactionsFilter
{
    _transactionsViewController.clickedFetchMore = NO;
    _transactionsViewController.filterIndex = FILTER_INDEX_ALL;
    [_transactionsViewController hideFilterLabel];
    self.mainLogoImageView.hidden = NO;
    [self.wallet reloadFilter];
    
    [self showFilterResults];
}

- (void)showFilterResults
{
    [self closeSideMenu];
    [_tabViewController setActiveViewController:_transactionsViewController animated:FALSE index:1];
}

- (void)reloadTopLevelViewControllers
{
    [_sendViewController reload];
    [_transactionsViewController reload];
    [_receiveViewController reload];
    [_accountsAndAddressesNavigationController reload];
    
    [sideMenuViewController reload];
}

- (void)showBusyViewWithLoadingText:(NSString *)text
{
    if (self.topViewControllerDelegate) {
        if ([self.topViewControllerDelegate respondsToSelector:@selector(showBusyViewWithLoadingText:)]) {
            [self.topViewControllerDelegate showBusyViewWithLoadingText:text];
        }
        return;
    }
    
    if (self.pinEntryViewController.inSettings &&
        ![text isEqualToString:BC_STRING_LOADING_SYNCING_WALLET] &&
        ![text isEqualToString:BC_STRING_LOADING_VERIFYING]) {
        DLog(@"Verify optional PIN view is presented - will not update busy views unless verifying or syncing");
        return;
    }
    
    if (_sendViewController.isSending && modalView) {
        DLog(@"Send progress modal is presented - will not show busy view");
        return;
    }
    
    [busyLabel setText:text];
    
    [_window.rootViewController.view bringSubviewToFront:busyView];
    
    if (busyView.alpha < 1.0) {
        [busyView fadeIn];
    }
}

- (void)updateBusyViewLoadingText:(NSString *)text
{
    if (self.topViewControllerDelegate) {
        if ([self.topViewControllerDelegate respondsToSelector:@selector(updateBusyViewLoadingText:)]) {
            [self.topViewControllerDelegate updateBusyViewLoadingText:text];
        }
        return;
    }
    
    if (self.pinEntryViewController.inSettings &&
        ![text isEqualToString:BC_STRING_LOADING_SYNCING_WALLET] &&
        ![text isEqualToString:BC_STRING_LOADING_VERIFYING]) {
        DLog(@"Verify optional PIN view is presented - will not update busy views unless verifying or syncing");
        return;
    }
    
    if (busyView.alpha == 1.0) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [busyLabel setText:text];
        }];
    }
}

- (void)showVerifyingBusyViewWithTimer:(NSInteger)timeInSeconds
{
    [self showBusyViewWithLoadingText:BC_STRING_LOADING_VERIFYING];
    self.loginTimer = [NSTimer scheduledTimerWithTimeInterval:timeInSeconds target:self selector:@selector(showErrorLoading) userInfo:nil repeats:NO];
}

- (void)showErrorLoading
{
    [self.loginTimer invalidate];

    if (!self.wallet.guid && busyView.alpha == 1.0 && [busyLabel.text isEqualToString:BC_STRING_LOADING_VERIFYING]) {
        [self.pinEntryViewController reset];
        [self hideBusyView];
        [self standardNotifyAutoDismissingController:BC_STRING_ERROR_LOADING_WALLET];
    }
}

- (void)hideBusyView
{
    if (self.topViewControllerDelegate) {
        if ([self.topViewControllerDelegate respondsToSelector:@selector(hideBusyView)]) {
            [self.topViewControllerDelegate hideBusyView];
        }
    }
    
    if (busyView.alpha == 1.0) {
        [busyView fadeOut];
    }
}

#pragma mark - AlertView Helpers

- (void)standardNotifyAutoDismissingController:(NSString *)message
{
    [self standardNotifyAutoDismissingController:message title:BC_STRING_ERROR];
}

- (void)standardNotifyAutoDismissingController:(NSString*)message title:(NSString*)title
{
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    
    if (self.topViewControllerDelegate) {
        if ([self.topViewControllerDelegate respondsToSelector:@selector(presentAlertController:)]) {
            [self.topViewControllerDelegate presentAlertController:alert];
        }
    } else {
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)standardNotify:(NSString*)message
{
    [self standardNotify:message title:BC_STRING_ERROR delegate:nil];
}

- (void)standardNotify:(NSString*)message delegate:(id)fdelegate
{
    [self standardNotify:message title:BC_STRING_ERROR delegate:fdelegate];
}

- (void)standardNotify:(NSString*)message title:(NSString*)title delegate:(id)fdelegate
{
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([[UIApplication sharedApplication] applicationState] == UIApplicationStateActive) {
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:title message:message  delegate:fdelegate cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
            [alert show];
        }
    });
}

# pragma mark - Wallet.js callbacks

- (void)walletDidLoad
{
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self endBackgroundUpdateTask];
    });
}

- (void)walletFailedToLoad
{
    DLog(@"walletFailedToLoad");
    // When doing a manual pair the wallet fails to load the first time because the server needs to verify via email that the user grants access to this device. In that case we don't want to display any additional errors besides the server error telling the user to check his email.
    if ([manualPairView isDescendantOfView:_window.rootViewController.view]) {
        return;
    }
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_FAILED_TO_LOAD_WALLET_TITLE
                                                    message:[NSString stringWithFormat:BC_STRING_FAILED_TO_LOAD_WALLET_DETAIL]
                                                   delegate:nil
                                          cancelButtonTitle:BC_STRING_FORGET_WALLET
                                          otherButtonTitles:BC_STRING_CLOSE_APP, nil];
    
    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        // Close App
        if (buttonIndex == 1) {
            UIApplication *app = [UIApplication sharedApplication];
            
            [app performSelector:@selector(suspend)];
        }
        // Forget Wallet
        else {
            [self confirmForgetWalletWithBlock:^(UIAlertView *alertView, NSInteger buttonIndex) {
                // Forget Wallet Cancelled
                if (buttonIndex == 0) {
                    // Open the Failed to load alert again
                    [self walletFailedToLoad];
                }
                // Forget Wallet Confirmed
                else if (buttonIndex == 1) {
                    [self forgetWallet];
                    [app showWelcome];
                }
            }];
        }
    };
    
    [alert show];
}

- (void)walletDidDecrypt
{
    DLog(@"walletDidDecrypt");
    
    if ([self isPinSet]) {
        [self showHdUpgradeIfAppropriate];
    }
    
    if (showSendCoins) {
        [self showSendCoins];
        showSendCoins = NO;
    }
    
    self.changedPassword = NO;
    
    [self setAccountData:wallet.guid sharedKey:wallet.sharedKey];
    
    //Becuase we are not storing the password on the device. We record the first few letters of the hashed password.
    //With the hash prefix we can then figure out if the password changed
    NSString * passwordPartHash = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_PASSWORD_PART_HASH];
    if (![[[app.wallet.password SHA256] substringToIndex:MIN([app.wallet.password length], 5)] isEqualToString:passwordPartHash]) {
        [self clearPin];
    }
}

- (void)walletDidFinishLoad
{
    DLog(@"walletDidFinishLoad");
    
    self.wallet.twoFactorInput = nil;
    
    [self.wallet getAccountInfo];
    
    [manualPairView clearTextFields];
    
    [app closeAllModals];
    
    if (![app isPinSet]) {
        [app showPinModalAsView:NO];
    }
    
    [_sendViewController reload];
    
    [self reloadTransactionFilterLabel];
    
    // Enabling touch ID and immediately backgrounding the app hides the status bar
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
}

- (void)didGetMultiAddressResponse:(MultiAddressResponse*)response
{
    self.latestResponse = response;
    
    _transactionsViewController.data = response;
    
#if defined(ENABLE_TRANSACTION_FILTERING) && defined(ENABLE_TRANSACTION_FETCHING)
    if (app.wallet.isFetchingTransactions) {
        [_transactionsViewController reload];
        app.wallet.isFetchingTransactions = NO;
    } else {
        [self reloadAfterMultiAddressResponse];
    }
#else
    [self reloadAfterMultiAddressResponse];
#endif
}

- (void)didSetLatestBlock:(LatestBlock*)block
{
    _transactionsViewController.latestBlock = block;
    [_transactionsViewController reload];
}

- (void)walletFailedToDecrypt
{
    DLog(@"walletFailedToDecrypt");
    // In case we were on the manual pair screen, we want to go back there. The way to check for that is that the wallet has a guid, but it's not saved yet
    if (wallet.guid && ![self guid]) {
        [self manualPairClicked:nil];
        
        return;
    }
    
    [self showPasswordModal];
}

- (void)showPasswordModal
{
    [self showModalWithContent:mainPasswordView closeType:ModalCloseTypeNone headerText:BC_STRING_PASSWORD_REQUIRED];
    
    forgetWalletButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    forgetWalletButton.titleEdgeInsets = UIEdgeInsetsMake(0, 10, 0, 10);
    forgetWalletButton.titleLabel.textAlignment = NSTextAlignmentCenter;
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:mainPasswordTextField action:@selector(resignFirstResponder)];
    mainPasswordTextField.text = @"";
    [mainPasswordView addGestureRecognizer:tapGesture];
}

- (void)beginBackgroundUpdateTask
{
    // We're using a background task to ensure we get enough time to sync. The bg task has to be ended before or when the timer expires, otherwise the app gets killed by the system.
    // Always kill the old handler before starting a new one. In case the system starts a bg task when the app goes into background, comes to foreground and goes to background before the first background task was ended. In that case the first background task is never killed and the system kills the app when the maximum time is up.
    [self endBackgroundUpdateTask];
    
    self.backgroundUpdateTask = [[UIApplication sharedApplication] beginBackgroundTaskWithExpirationHandler:^{
        [self endBackgroundUpdateTask];
    }];
}

- (void)endBackgroundUpdateTask
{
    if (self.backgroundUpdateTask != UIBackgroundTaskInvalid) {
        [[UIApplication sharedApplication] endBackgroundTask:self.backgroundUpdateTask];
        self.backgroundUpdateTask = UIBackgroundTaskInvalid;
    }
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Fade out the LaunchImage
    [UIView animateWithDuration:0.25 animations:^{
        curtainImageView.alpha = 0;
    } completion:^(BOOL finished) {
        [curtainImageView removeFromSuperview];
    }];
    
    if (self.tabViewController.activeViewController == _receiveViewController && modalView) {
        [_receiveViewController showKeyboard];
    }
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    if (!curtainImageView) {
        [self setupCurtainView];
    }
    
    // Dismiss sendviewController keyboard
    if (_sendViewController) {
        [_sendViewController hideKeyboard];
        
        // Make sure the the send payment button on send screen is enabled (bug when second password requested and app is backgrounded)
        [_sendViewController enablePaymentButtons];
    }
    
    // Dismiss receiveCoinsViewController keyboard
    if (_receiveViewController) {
        [_receiveViewController hideKeyboard];
    }
    
    if (createWalletView) {
        [createWalletView hideKeyboard];
    }
    
    if (manualPairView) {
        [manualPairView hideKeyboard];
    }
    
    if ([mainPasswordTextField isFirstResponder]) {
        [mainPasswordTextField resignFirstResponder];
    }
    
    // Show the LaunchImage so the list of running apps does not show the user's information
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.25 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Small delay so we don't change the view while it's zooming out
        
        [self.window addSubview:curtainImageView];
        [self.window bringSubviewToFront:curtainImageView];
        
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            curtainImageView.alpha = 1;
        } completion:^(BOOL finished) {
            // Dismiss any ViewControllers that are used modally, except for the MerchantViewController
            if (_tabViewController.presentedViewController == _bcWebViewController) {
                [_bcWebViewController dismissViewControllerAnimated:NO completion:nil];
            }
        }];
    });
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [self.loginTimer invalidate];
    
    [_window.rootViewController dismissViewControllerAnimated:NO completion:nil];
    
    // Close all modals
    [app closeAllModals];
    
    self.topViewControllerDelegate = nil;
    
    // Close screens that shouldn't be in the foreground when returning to the wallet
    if (_backupNavigationViewController) {
        [_backupNavigationViewController dismissViewControllerAnimated:NO completion:nil];
    }
    
    if (_settingsNavigationController) {
        [_settingsNavigationController dismissViewControllerAnimated:NO completion:nil];
    }
    
    app.transactionsViewController.loadedAllTransactions = NO;
    app.wallet.isFetchingTransactions = NO;

    [self closeSideMenu];
    
    // Close PIN Modal in case we are setting it (after login or when changing the PIN)
    if (self.pinEntryViewController.verifyOnly == NO || self.pinEntryViewController.inSettings == NO) {
        [self closePINModal:NO];
    }
    
    // Show pin modal before we close the app so the PIN verify modal gets shown in the list of running apps and immediately after we restart
    if ([self isPinSet]) {
        [self showPinModalAsView:YES];
        [self.pinEntryViewController reset];
    }
    
    if ([wallet isInitialized]) {
        [self beginBackgroundUpdateTask];
        
        [self logout];
    }
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // The PIN modal is shown on ResignActive, but we don't want to override the modal with the welcome screen
    if ([self isPinSet]) {
#ifdef TOUCH_ID_ENABLED
        if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED]) {
            [self authenticateWithTouchID];
        }
#endif
        return;
    }
    
    if (![wallet isInitialized]) {
        [app showWelcome];
        
        if ([self guid] && [self sharedKey]) {
            [self showPasswordModal];
        }
    }
}

- (void)playBeepSound
{
    if (beepSoundID == 0) {
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: [[NSBundle mainBundle] pathForResource:@"beep" ofType:SOUND_FORMAT]], &beepSoundID);
    }
    
    AudioServicesPlaySystemSound(beepSoundID);
}

- (void)playAlertSound
{
    if (alertSoundID == 0) {
        //Find the Alert Sound
        NSString * alert_sound = [[NSBundle mainBundle] pathForResource:@"alert-received" ofType:SOUND_FORMAT];
        
        //Create the system sound
        AudioServicesCreateSystemSoundID((__bridge CFURLRef)[NSURL fileURLWithPath: alert_sound], &alertSoundID);
    }
    
    AudioServicesPlaySystemSound(alertSoundID);
}

- (void)pushWebViewController:(NSString*)url title:(NSString *)title
{
    _bcWebViewController = [[BCWebViewController alloc] initWithTitle:title];
    [_bcWebViewController loadURL:url];
    _bcWebViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_tabViewController presentViewController:_bcWebViewController animated:YES completion:nil];
}

- (NSMutableDictionary *)parseQueryString:(NSString *)query
{
    NSMutableDictionary *dict = [[NSMutableDictionary alloc] initWithCapacity:6];
    NSArray *pairs = [query componentsSeparatedByString:@"&"];
    
    for (NSString *pair in pairs) {
        NSArray *elements = [pair componentsSeparatedByString:@"="];
        if ([elements count] >= 2) {
            NSString *key = [[elements objectAtIndex:0] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            NSString *val = [[elements objectAtIndex:1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            
            [dict setObject:val forKey:key];
        }
    }
    return dict;
}

- (NSDictionary*)parseURI:(NSString*)urlString
{
    if (!urlString) {
        return nil;
    }
    
    if (![urlString hasPrefix:PREFIX_BITCOIN_URI]) {
        return [NSDictionary dictionaryWithObject:urlString forKey:DICTIONARY_KEY_ADDRESS];
    }
    
    NSString * replaced = [[urlString stringByReplacingOccurrencesOfString:PREFIX_BITCOIN_URI withString:[NSString stringWithFormat:@"%@//", PREFIX_BITCOIN_URI]] stringByReplacingOccurrencesOfString:@"////" withString:@"//"];
    
    NSURL * url = [NSURL URLWithString:replaced];
    
    NSMutableDictionary *dict = [self parseQueryString:[url query]];
    
    if ([url host] != NULL)
        [dict setObject:[url host] forKey:DICTIONARY_KEY_ADDRESS];
    
    return dict;
}

- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
    if (![self isPinSet]) {
        return NO;
    }
    
    [app closeModalWithTransition:kCATransitionFade];
    
    showSendCoins = YES;
    
    if (!_sendViewController) {
        // really no reason to lazyload anymore...
        _sendViewController = [[SendViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
    }
    
    NSDictionary *dict = [self parseURI:[url absoluteString]];
    NSString * addr = [dict objectForKey:DICTIONARY_KEY_ADDRESS];
    NSString * amount = [dict objectForKey:DICTIONARY_KEY_AMOUNT];
    
    [_sendViewController setAmountFromUrlHandler:amount withToAddress:addr];
    [_sendViewController reload];
    
    return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField*)textField
{
    if (textField == secondPasswordTextField) {
        if (validateSecondPassword) {
            [self secondPasswordClicked:textField];
        } else {
            [self privateKeyPasswordClicked];
        }
    }
    else if (textField == mainPasswordTextField) {
        [self mainPasswordClicked:textField];
    }
    
    return YES;
}

- (void)getPrivateKeyPassword:(void (^)(NSString *))success error:(void (^)(NSString *))error
{
    validateSecondPassword = FALSE;
    
    secondPasswordDescriptionLabel.text = BC_STRING_PRIVATE_KEY_ENCRYPTED_DESCRIPTION;
    
    if (self.topViewControllerDelegate) {
        BCModalViewController *bcModalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:BC_STRING_PASSWORD_REQUIRED view:secondPasswordView];
        
        addPrivateKeySuccess = success;

        [self.topViewControllerDelegate presentViewController:bcModalViewController animated:YES completion:^{
            UIButton *secondPasswordOverlayButton = [[UIButton alloc] initWithFrame:[secondPasswordView convertRect:secondPasswordButton.frame toView:bcModalViewController.view]];
            [bcModalViewController.view addSubview:secondPasswordOverlayButton];
            [secondPasswordOverlayButton addTarget:self action:@selector(privateKeyPasswordClicked) forControlEvents:UIControlEventTouchUpInside];
        }];
        
        [bcModalViewController.closeButton addTarget:self action:@selector(closeAllModals) forControlEvents:UIControlEventAllTouchEvents];
    } else {
        [app showModalWithContent:secondPasswordView closeType:ModalCloseTypeClose headerText:BC_STRING_PASSWORD_REQUIRED onDismiss:^() {
            NSString * password = secondPasswordTextField.text;
        
            if ([password length] == 0) {
                if (error) error(BC_STRING_NO_PASSWORD_ENTERED);
            } else {
                if (success) success(password);
            }
        
            secondPasswordTextField.text = nil;
        } onResume:nil];
        
        [modalView.closeButton removeTarget:self action:@selector(closeModalClicked:) forControlEvents:UIControlEventAllTouchEvents];
        
        [modalView.closeButton addTarget:self action:@selector(closeAllModals) forControlEvents:UIControlEventAllTouchEvents];
    }
    
    [secondPasswordTextField becomeFirstResponder];
}

- (void)privateKeyPasswordClicked
{
    NSString * password = secondPasswordTextField.text;
    
    if ([password length] == 0) {
        [self standardNotifyAutoDismissingController:BC_STRING_NO_PASSWORD_ENTERED];
    } else {
        if (_tabViewController.presentedViewController) {
            [_tabViewController.presentedViewController dismissViewControllerAnimated:YES completion:nil];
        } else {
            [self closeModalWithTransition:kCATransitionFade];
        }
        if (addPrivateKeySuccess) addPrivateKeySuccess(password);
    }
    
    secondPasswordTextField.text = nil;
}

- (IBAction)secondPasswordClicked:(id)sender
{
    NSString *password = secondPasswordTextField.text;
    
    if ([password length] == 0) {
        [app standardNotifyAutoDismissingController:BC_STRING_NO_PASSWORD_ENTERED];
    } else if(validateSecondPassword && ![wallet validateSecondPassword:password]) {
        [app standardNotifyAutoDismissingController:BC_STRING_SECOND_PASSWORD_INCORRECT];
    } else {
        if (secondPasswordSuccess) {
            // It takes ANIMATION_DURATION to dismiss the second password view, then a little extra to make sure any wait spinners start spinning before we execute the success function.
            dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(1.5*ANIMATION_DURATION * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
                if (secondPasswordSuccess) {
                    secondPasswordSuccess(password);
                    secondPasswordSuccess = nil;
                }
            });
        }
        [app closeModalWithTransition:kCATransitionFade];
    }
    
    secondPasswordTextField.text = nil;
}

- (void)getSecondPassword:(void (^)(NSString *))success error:(void (^)(NSString *))error
{
    secondPasswordDescriptionLabel.text = BC_STRING_ACTION_REQUIRES_SECOND_PASSWORD;
    
    validateSecondPassword = TRUE;
    
    secondPasswordSuccess = success;
    
    if (self.topViewControllerDelegate) {
        BCModalViewController *bcModalViewController = [[BCModalViewController alloc] initWithCloseType:ModalCloseTypeClose showHeader:YES headerText:BC_STRING_SECOND_PASSWORD_REQUIRED view:secondPasswordView];
        
        [self.topViewControllerDelegate presentViewController:bcModalViewController animated:YES completion:^{
            UIButton *secondPasswordOverlayButton = [[UIButton alloc] initWithFrame:[secondPasswordView convertRect:secondPasswordButton.frame toView:bcModalViewController.view]];
            [bcModalViewController.view addSubview:secondPasswordOverlayButton];
            [secondPasswordOverlayButton addTarget:self action:@selector(secondPasswordClicked:) forControlEvents:UIControlEventTouchUpInside];
        }];
        
        [bcModalViewController.closeButton addTarget:self action:@selector(closeAllModals) forControlEvents:UIControlEventAllTouchEvents];
    } else {
        [app showModalWithContent:secondPasswordView closeType:ModalCloseTypeClose headerText:BC_STRING_SECOND_PASSWORD_REQUIRED onDismiss:^() {
            secondPasswordTextField.text = nil;
            [self.sendViewController enablePaymentButtons];
        } onResume:nil];
        
        [modalView.closeButton removeTarget:self action:@selector(closeModalClicked:) forControlEvents:UIControlEventAllTouchEvents];
        
        [modalView.closeButton addTarget:self action:@selector(closeAllModals) forControlEvents:UIControlEventAllTouchEvents];
        
        if (_sendViewController.transferAllMode) {
            [modalView.closeButton addTarget:_sendViewController action:@selector(reload) forControlEvents:UIControlEventAllTouchEvents];
        }
    }
    
    [secondPasswordTextField becomeFirstResponder];
}

- (void)closeAllModals
{
    [self hideBusyView];
    
    secondPasswordSuccess = nil;
    secondPasswordTextField.text = nil;
    
    self.wallet.isSyncing = NO;
    
    [modalView endEditing:YES];
    
    [modalView removeFromSuperview];
    
    CATransition *animation = [CATransition animation];
    [animation setDuration:ANIMATION_DURATION];
    [animation setType:kCATransitionFade];
    
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[_window layer] addAnimation:animation forKey:ANIMATION_KEY_HIDE_MODAL];
    
    if (self.modalView.onDismiss) {
        self.modalView.onDismiss();
        self.modalView.onDismiss = nil;
    }
    
    self.modalView = nil;
    
    for (BCModalView *modalChainView in self.modalChain) {
        
        for (UIView *subView in [modalChainView.myHolderView subviews]) {
            [subView removeFromSuperview];
        }
        
        [modalChainView.myHolderView removeFromSuperview];
        
        if (modalChainView.onDismiss) {
            modalChainView.onDismiss();
        }
    }
    
    [self.modalChain removeAllObjects];
}

- (void)closeModalWithTransition:(NSString *)transition
{
    [[NSNotificationCenter defaultCenter] postNotificationName:NOTIFICATION_KEY_MODAL_VIEW_DISMISSED object:nil];
    
    [modalView removeFromSuperview];
    
    CATransition *animation = [CATransition animation];
    // There are two types of transitions: movement based and fade in/out. The movement based ones can have a subType to set which direction the movement is in. In case the transition parameter is a direction, we use the MoveIn transition and the transition parameter as the direction, otherwise we use the transition parameter as the transition type.
    [animation setDuration:ANIMATION_DURATION];
    if (transition != kCATransitionFade) {
        [animation setType:kCATransitionMoveIn];
        [animation setSubtype:transition];
    }
    else {
        [animation setType:transition];
    }
    
    [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
    [[_window layer] addAnimation:animation forKey:ANIMATION_KEY_HIDE_MODAL];
    
    if (self.modalView.onDismiss) {
        self.modalView.onDismiss();
        self.modalView.onDismiss = nil;
    }
    
    if ([self.modalChain count] > 0) {
        BCModalView * previousModalView = [self.modalChain objectAtIndex:[self.modalChain count]-1];
        
        [_window.rootViewController.view addSubview:previousModalView];
        
        [_window.rootViewController.view bringSubviewToFront:busyView];
        
        [_window.rootViewController.view endEditing:TRUE];
        
        if (self.modalView.onResume) {
            self.modalView.onResume();
        }
        
        self.modalView = previousModalView;
        
        [self.modalChain removeObjectAtIndex:[self.modalChain count]-1];
    }
    else {
        self.modalView = nil;
    }
}

- (void)showModalWithContent:(UIView *)contentView closeType:(ModalCloseType)closeType headerText:(NSString *)headerText
{
    [self showModalWithContent:(BCModalContentView *)contentView closeType:closeType showHeader:YES headerText:headerText onDismiss:nil onResume:nil];
}

- (void)showModalWithContent:(UIView *)contentView closeType:(ModalCloseType)closeType headerText:(NSString *)headerText onDismiss:(void (^)())onDismiss onResume:(void (^)())onResume
{
    [self showModalWithContent:(BCModalContentView *)contentView closeType:closeType showHeader:YES headerText:headerText onDismiss:onDismiss onResume:onResume];
}

- (void)showModalWithContent:(UIView *)contentView closeType:(ModalCloseType)closeType showHeader:(BOOL)showHeader headerText:(NSString *)headerText onDismiss:(void (^)())onDismiss onResume:(void (^)())onResume
{
    // Remove the modal if we have one
    if (modalView) {
        [modalView removeFromSuperview];
        
        if (modalView.closeType != ModalCloseTypeNone) {
            if (modalView.onDismiss) {
                modalView.onDismiss();
                modalView.onDismiss = nil;
            }
        } else {
            [self.modalChain addObject:modalView];
        }
        
        self.modalView = nil;
    }
    
    // Show modal
    modalView = [[BCModalView alloc] initWithCloseType:closeType showHeader:showHeader headerText:headerText];
    self.modalView.onDismiss = onDismiss;
    self.modalView.onResume = onResume;
    if (onResume) {
        onResume();
    }
    
    if ([contentView respondsToSelector:@selector(prepareForModalPresentation)]) {
        [(BCModalContentView *)contentView prepareForModalPresentation];
    }
    
    [modalView.myHolderView addSubview:contentView];
    
    contentView.frame = CGRectMake(0, 0, modalView.myHolderView.frame.size.width, modalView.myHolderView.frame.size.height);
    
    [_window.rootViewController.view addSubview:modalView];
    [_window.rootViewController.view endEditing:TRUE];
    
    @try {
        CATransition *animation = [CATransition animation];
        [animation setDuration:ANIMATION_DURATION];
        
        if (closeType == ModalCloseTypeBack) {
            [animation setType:kCATransitionMoveIn];
            [animation setSubtype:kCATransitionFromRight];
        }
        else {
            [animation setType:kCATransitionFade];
        }
        
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        [[_window.rootViewController.view layer] addAnimation:animation forKey:ANIMATION_KEY_SHOW_MODAL];
    } @catch (NSException * e) {
        DLog(@"Animation Exception %@", e);
    }
}

- (void)didFailBackupWallet
{
    // Refresh the wallet and history
    [self.wallet getWalletAndHistory];
}

- (void)didBackupWallet
{
    [self reload];
}

- (void)setAccountData:(NSString*)guid sharedKey:(NSString*)sharedKey
{
    if ([guid length] != 36) {
        [app standardNotify:BC_STRING_INVALID_GUID];
        return;
    }
    
    if ([sharedKey length] != 36) {
        [app standardNotify:BC_STRING_INVALID_SHARED_KEY];
        return;
    }
    
    [self setGuidInKeychain:guid];
    [self setSharedKeyInKeychain:sharedKey];
}

- (BOOL)isQRCodeScanningSupported
{
    NSUInteger platformType = [[UIDevice currentDevice] platformType];
    
    if (platformType ==  UIDeviceiPhoneSimulator || platformType ==  UIDeviceiPhoneSimulatoriPhone  || platformType ==  UIDeviceiPhoneSimulatoriPhone || platformType ==  UIDevice1GiPhone || platformType ==  UIDevice3GiPhone || platformType ==  UIDevice1GiPod || platformType ==  UIDevice2GiPod || ![UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        return FALSE;
    }
    
    return TRUE;
}

- (IBAction)scanAccountQRCodeclicked:(id)sender
{
    if (![self getCaptureDeviceInput]) {
        return;
    }
    
    PairingCodeParser * pairingCodeParser = [[PairingCodeParser alloc] initWithSuccess:^(NSDictionary*code) {
        DLog(@"scanAndParse success");
        
        [app forgetWallet];
        
        [app clearPin];
        
        [self.wallet loadWalletWithGuid:[code objectForKey:QR_CODE_KEY_GUID] sharedKey:[code objectForKey:QR_CODE_KEY_SHARED_KEY] password:[code objectForKey:QR_CODE_KEY_PASSWORD]];
        
        self.wallet.delegate = self;
        
        wallet.didPairAutomatically = YES;
        
    } error:^(NSString*error) {
        [app standardNotify:error];
    }];
    
    [self.slidingViewController presentViewController:pairingCodeParser animated:YES completion:nil];
}

- (void)scanPrivateKeyForWatchOnlyAddress:(NSString *)address
{
    if (![app getCaptureDeviceInput]) {
        return;
    }
    
    PrivateKeyReader *reader = [[PrivateKeyReader alloc] initWithSuccess:^(NSString* privateKeyString) {
        [app.wallet addKey:privateKeyString toWatchOnlyAddress:address];
    } error:nil acceptPublicKeys:NO busyViewText:BC_STRING_LOADING_IMPORT_KEY];
    
    [[NSNotificationCenter defaultCenter] addObserver:reader selector:@selector(autoDismiss) name:NOTIFICATION_KEY_RELOAD_TO_DISMISS_VIEWS object:nil];
    
    if (self.topViewControllerDelegate) {
        [self.topViewControllerDelegate presentViewController:reader animated:YES completion:nil];
    } else {
        [_window.rootViewController presentViewController:reader animated:YES completion:nil];
    }
    
    app.wallet.lastScannedWatchOnlyAddress = address;
}

- (void)askUserToAddWatchOnlyAddress:(NSString *)address success:(void (^)(NSString *))success
{
    UIAlertController *alertToWarnAboutWatchOnly = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING_TITLE message:[NSString stringWithFormat:@"%@\n\n%@", BC_STRING_ADD_WATCH_ONLY_ADDRESS_WARNING_ONE, BC_STRING_ADD_WATCH_ONLY_ADDRESS_WARNING_TWO] preferredStyle:UIAlertControllerStyleAlert];
    [alertToWarnAboutWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        if (success) {
            success(address);
        }
    }]];
    [alertToWarnAboutWatchOnly addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    
    if (self.topViewControllerDelegate) {
        [self.topViewControllerDelegate presentViewController:alertToWarnAboutWatchOnly animated:YES completion:nil];
    } else {
        [_window.rootViewController presentViewController:alertToWarnAboutWatchOnly animated:YES completion:nil];
    }
}

- (void)logout
{
    [self.loginTimer invalidate];
    
    [self.wallet loadBlankWallet];
    
    self.latestResponse = nil;
    
    _transactionsViewController.data = nil;
    _settingsNavigationController = nil;

    [self reload];
}

- (void)forgetWallet
{
    [self clearPin];
    
    // Clear all cookies (important one is the server session id SID)
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    for (NSHTTPCookie *each in cookieStorage.cookies) {
        [cookieStorage deleteCookie:each];
    }
    
    self.wallet.sessionToken = nil;
    
    self.merchantViewController = nil;
    
    [self removeGuidFromKeychain];
    [self removeSharedKeyFromKeychain];
        
    [self.wallet clearLocalStorage];
    
    [self.wallet loadBlankWallet];
    
    self.latestResponse = nil;
    
    [_transactionsViewController setData:nil];
    
    [self reload];
    
    [[NSUserDefaults standardUserDefaults] setObject:nil forKey:USER_DEFAULTS_KEY_BUNDLE_VERSION_STRING];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    [self transitionToIndex:1];
}

- (void)didImportKey:(NSString *)address
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    
    self.wallet.lastImportedAddress = address;
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertUserOfImportedKey) name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
}

- (void)alertUserOfImportedKey
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
    
    NSString *messageWithArgument = [app.wallet isWatchOnlyLegacyAddress:self.wallet.lastImportedAddress] ? BC_STRING_IMPORTED_WATCH_ONLY_ADDRESS_ARGUMENT : BC_STRING_IMPORTED_PRIVATE_KEY_ARGUMENT;
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_SUCCESS message:[NSString stringWithFormat:messageWithArgument, self.wallet.lastImportedAddress] preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:UIApplicationDidEnterBackgroundNotification object:nil];
    if (self.topViewControllerDelegate) {
        if ([self.topViewControllerDelegate respondsToSelector:@selector(presentAlertController:)]) {
            [self.topViewControllerDelegate presentAlertController:alert];
        }
    } else {
        [_window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)didImportIncorrectPrivateKey:(NSString *)address
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertUserOfImportedIncorrectPrivateKey) name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
}

- (void)alertUserOfImportedIncorrectPrivateKey
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];

    NSString *message = [NSString stringWithFormat:@"%@\n\n%@", BC_STRING_INCORRECT_PRIVATE_KEY_IMPORTED_MESSAGE_ONE, BC_STRING_INCORRECT_PRIVATE_KEY_IMPORTED_MESSAGE_TWO];
    
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_SUCCESS message:message preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    if (self.topViewControllerDelegate) {
        if ([self.topViewControllerDelegate respondsToSelector:@selector(presentAlertController:)]) {
            [self.topViewControllerDelegate presentAlertController:alert];
        }
    } else {
        [_window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)didImportPrivateKeyToLegacyAddress
{
    [app showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alertUserOfImportedPrivateKeyIntoLegacyAddress) name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
}

- (void)alertUserOfImportedPrivateKeyIntoLegacyAddress
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_SUCCESS message:BC_STRING_IMPORTED_PRIVATE_KEY_SUCCESS preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:alert selector:@selector(autoDismiss) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    if (self.topViewControllerDelegate) {
        if ([self.topViewControllerDelegate respondsToSelector:@selector(presentAlertController:)]) {
            [self.topViewControllerDelegate presentAlertController:alert];
        }
    } else {
        [_window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)didFailToImportPrivateKey:(NSString *)error
{
    [[NSNotificationCenter defaultCenter] removeObserver:self.receiveViewController name:NOTIFICATION_KEY_BACKUP_SUCCESS object:nil];
    [self hideBusyView];
    self.wallet.isSyncing = NO;
    
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:error preferredStyle:UIAlertControllerStyleAlert];
    [errorAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [[NSNotificationCenter defaultCenter] addObserver:errorAlert selector:@selector(autoDismiss) name:UIApplicationDidEnterBackgroundNotification object:nil];
    
    if (self.topViewControllerDelegate) {
        if ([self.topViewControllerDelegate respondsToSelector:@selector(presentAlertController:)]) {
            [self.topViewControllerDelegate presentAlertController:errorAlert];
        }
    } else {
        [_window.rootViewController presentViewController:errorAlert animated:YES completion:nil];
    }
}

- (void)didFailToImportPrivateKeyForWatchOnlyAddress:(NSString *)error
{
    [self hideBusyView];
    self.wallet.isSyncing = NO;
    
    NSString *alertTitle = BC_STRING_ERROR;
    if ([error isEqualToString:ERROR_NOT_PRESENT_IN_WALLET]) {
        error = BC_STRING_ADDRESS_NOT_PRESENT_IN_WALLET;
    } else if ([error isEqualToString:ERROR_ADDRESS_NOT_WATCH_ONLY]) {
        error = BC_STRING_ADDRESS_NOT_WATCH_ONLY;
    } else if ([error isEqualToString:ERROR_WRONG_BIP_PASSWORD]) {
        error = BC_STRING_WRONG_BIP38_PASSWORD;
    } else if ([error isEqualToString:ERROR_PRIVATE_KEY_OF_ANOTHER_WATCH_ONLY_ADDRESS]) {
        error = BC_STRING_KEY_BELONGS_TO_OTHER_ADDRESS_NOT_WATCH_ONLY;
    }
    
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:alertTitle message:error preferredStyle:UIAlertControllerStyleAlert];
    [errorAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [errorAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_TRY_AGAIN style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [self scanPrivateKeyForWatchOnlyAddress:self.wallet.lastScannedWatchOnlyAddress];
    }]];

    [[NSNotificationCenter defaultCenter] addObserver:errorAlert selector:@selector(autoDismiss) name:UIApplicationDidEnterBackgroundNotification object:nil];

    if (self.topViewControllerDelegate) {
        if ([self.topViewControllerDelegate respondsToSelector:@selector(presentAlertController:)]) {
            [self.topViewControllerDelegate presentAlertController:errorAlert];
        }
    } else {
        [_window.rootViewController presentViewController:errorAlert animated:YES completion:nil];
    }
}

- (void)didFailRecovery
{
    [createWalletView didFailRecovery];
}

- (void)didRecoverWallet
{
    [createWalletView didRecoverWallet];
}

- (void)didFailGetHistory:(NSString *)error
{
    NSString *errorMessage = [error length] == 0 ? BC_STRING_SEND_ERROR_NO_INTERNET_CONNECTION : error;

    UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:errorMessage preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        if ([self isPinSet]) {
            [self showPinModalAsView:NO];
        } else {
            UIApplication *app = [UIApplication sharedApplication];
            [app performSelector:@selector(suspend)];
        }
    }]];
    
    [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
}

- (void)didGenerateNewAddress
{
    [app.accountsAndAddressesNavigationController didGenerateNewAddress];
}

- (void)returnToAddressesScreen
{
    if (self.accountsAndAddressesNavigationController) {
        [self.accountsAndAddressesNavigationController popToRootViewControllerAnimated:YES];
    }
}

- (void)alertUserOfInvalidAccountName
{
    [self standardNotifyAutoDismissingController:BC_STRING_NAME_ALREADY_IN_USE];
    
    [self hideBusyView];
}

- (void)alertUserOfInvalidPrivateKey
{
    [self standardNotifyAutoDismissingController:BC_STRING_INCORRECT_PRIVATE_KEY];
}

- (void)sendFromWatchOnlyAddress
{
    [_sendViewController sendFromWatchOnlyAddress];
}

- (void)didCheckForOverSpending:(NSNumber *)amount fee:(NSNumber *)fee
{
    [_sendViewController didCheckForOverSpending:amount fee:fee];
}

- (void)didGetMaxFee:(NSNumber *)fee amount:(NSNumber *)amount dust:(NSNumber *)dust willConfirm:(BOOL)willConfirm
{
    [_sendViewController didGetMaxFee:fee amount:amount dust:dust willConfirm:willConfirm];
}

- (void)didGetFee:(NSNumber *)fee dust:(NSNumber *)dust
{
    [_sendViewController didGetFee:fee dust:dust];
}

- (void)didChangeForcedFee:(NSNumber *)fee dust:(NSNumber *)dust
{
    [_sendViewController didChangeForcedFee:fee dust:dust];
}

- (void)didGetFeeBounds:(NSArray *)bounds confirmationEstimation:(NSNumber *)confirmationEstimation maxAmounts:(NSArray *)maxAmounts maxFees:(NSArray *)maxFees
{
    [_sendViewController didGetFeeBounds:(NSArray *)bounds confirmationEstimation:confirmationEstimation maxAmounts:maxAmounts maxFees:maxFees];
}

- (void)didGetSurgeStatus:(BOOL)surgeStatus
{
    _sendViewController.surgeIsOccurring = surgeStatus;
}

- (void)enableSendPaymentButtons
{
    [_sendViewController enablePaymentButtons];
}

- (void)updateSendBalance:(NSNumber *)balance
{
    [_sendViewController updateSendBalance:balance];
}

- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed
{
    [_sendViewController updateTransferAllAmount:amount fee:fee addressesUsed:addressesUsed];
}

- (void)showSummaryForTransferAll
{
    [_sendViewController showSummaryForTransferAll];
}

- (void)sendDuringTransferAll:(NSString *)secondPassword
{
    [_sendViewController sendDuringTransferAll:secondPassword];
}

- (void)didErrorDuringTransferAll:(NSString *)error secondPassword:(NSString *)secondPassword
{
    [_sendViewController didErrorDuringTransferAll:error secondPassword:secondPassword];
}

- (void)updateLoadedAllTransactions:(NSNumber *)loadedAll
{
    _transactionsViewController.loadedAllTransactions = [loadedAll boolValue];
}

#pragma mark - Show Screens

- (void)showAccountsAndAddresses
{
    if (!_accountsAndAddressesNavigationController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_ACCOUNTS_AND_ADDRESSES bundle:nil];
        self.accountsAndAddressesNavigationController = [storyboard instantiateViewControllerWithIdentifier:NAVIGATION_CONTROLLER_NAME_ACCOUNTS_AND_ADDRESSES];
    }
    
    self.topViewControllerDelegate = self.accountsAndAddressesNavigationController;
    self.accountsAndAddressesNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [_tabViewController presentViewController:self.accountsAndAddressesNavigationController animated:YES completion:^{
        if (![[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_HIDE_TRANSFER_ALL_FUNDS_ALERT] && self.accountsAndAddressesNavigationController.viewControllers.count == 1 && [app.wallet didUpgradeToHd] && [app.wallet getTotalBalanceForSpendableActiveLegacyAddresses] >= [app.wallet dust]) {
            [self.accountsAndAddressesNavigationController alertUserToTransferAllFunds:NO];
        }
    }];
}

- (void)showSecurityCenter
{
    if (!_settingsNavigationController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_SETTINGS bundle: nil];
        self.settingsNavigationController = [storyboard instantiateViewControllerWithIdentifier:NAVIGATION_CONTROLLER_NAME_SETTINGS];
    }
    
    [self.settingsNavigationController showSecurityCenter];
    
    self.settingsNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_tabViewController presentViewController:self.settingsNavigationController animated:YES completion:nil];
}

- (void)showSettings
{
    if (!_settingsNavigationController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_SETTINGS bundle: nil];
        self.settingsNavigationController = [storyboard instantiateViewControllerWithIdentifier:NAVIGATION_CONTROLLER_NAME_SETTINGS];
    }
    
    [self.settingsNavigationController showSettings];
    
    self.settingsNavigationController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_tabViewController presentViewController:self.settingsNavigationController animated:YES completion:nil];
}

- (void)showBackup
{
    if (!_backupNavigationViewController) {
        UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_BACKUP bundle: nil];
        _backupNavigationViewController = [storyboard instantiateViewControllerWithIdentifier:NAVIGATION_CONTROLLER_NAME_BACKUP];
    }
    
    // Pass the wallet to the backup navigation controller, so we don't have to make the AppDelegate available in Swift.
    _backupNavigationViewController.wallet = self.wallet;
    
    _backupNavigationViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_tabViewController presentViewController:_backupNavigationViewController animated:YES completion:nil];
}

- (void)showSupport
{
    // Send email using the Message UI Framework: http://stackoverflow.com/a/1513433/2076094
    // If the user has not email account set up, he should get a notification saying he can't send emails (tested on iOS 7.1.1)
    MFMailComposeViewController *emailViewController = [[MFMailComposeViewController alloc] init];
    
    if (emailViewController != nil) {
        emailViewController.mailComposeDelegate = self;
        emailViewController.navigationBar.tintColor = COLOR_BLOCKCHAIN_BLUE;
        [emailViewController setToRecipients:@[SUPPORT_EMAIL_ADDRESS]];
        [emailViewController setSubject:BC_STRING_SUPPORT_EMAIL_SUBJECT];
        
        NSString *message = [NSString stringWithFormat:@"Dear Blockchain Support,\n\n\n\n--\nApp: %@\nSystem: %@ %@\nDevice: %@\n",
                             [UncaughtExceptionHandler appNameAndVersionNumberDisplayString],
                             [[UIDevice currentDevice] systemName],
                             [[UIDevice currentDevice] systemVersion],
                             [DeviceIdentifier deviceName]];
        [emailViewController setMessageBody:message isHTML:NO];
        
        emailViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
        [self.tabViewController presentViewController:emailViewController animated:YES completion:^{
            UIAlertController *instructionsAlert = [UIAlertController alertControllerWithTitle:BC_STRING_SUPPORT_EMAIL_SUBJECT message:BC_STRING_SUPPORT_INSTRUCTIONS preferredStyle:UIAlertControllerStyleAlert];
            [instructionsAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
            [emailViewController presentViewController:instructionsAlert animated:YES completion:nil];
        }];
    } else {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:[NSString stringWithFormat:BC_STRING_NO_EMAIL_CONFIGURED, SUPPORT_EMAIL_ADDRESS] preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
    }
}

- (void)showSendCoins
{
    if (!_sendViewController) {
        _sendViewController = [[SendViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
    }
    
    [_tabViewController setActiveViewController:_sendViewController animated:TRUE index:0];
}

- (void)showDebugMenu:(int)presenter
{
    DebugTableViewController *debugViewController = [[DebugTableViewController alloc] init];
    debugViewController.presenter = presenter;
    
    UINavigationController *navigationController = [[UINavigationController alloc] initWithRootViewController:debugViewController];
    
    [self.window.rootViewController presentViewController:navigationController animated:YES completion:nil];
}

- (void)showPinModalAsView:(BOOL)asView
{
    if (self.changedPassword) {
        [self showPasswordModal];
        return;
    }
    
    // Backgrounding from resetting PIN screen hides the status bar
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
    
    // Don't show a new one if we already show it
    if ([self.pinEntryViewController.view isDescendantOfView:_window.rootViewController.view] ||
        ( _tabViewController.presentedViewController != nil &&_tabViewController.presentedViewController == self.pinEntryViewController && !_pinEntryViewController.isBeingDismissed)) {
        return;
    }
    
    // if pin exists - verify
    if ([self isPinSet]) {
        self.pinEntryViewController = [PEPinEntryController pinVerifyController];
    }
    // no pin - create
    else {
        self.pinEntryViewController = [PEPinEntryController pinCreateController];
    }
    
    self.pinEntryViewController.navigationBarHidden = YES;
    self.pinEntryViewController.pinDelegate = self;
    
    // asView inserts the modal's view into the rootViewController as a view - this is only used in didFinishLaunching so there is no delay when showing the PIN on start
    if (asView) {
        if ([_settingsNavigationController isBeingPresented]) {
            // Immediately after enabling touch ID, backgrounding the app while the Settings scren is still being presented results in failure to add the PIN screen back. Using a delay to allow animation to complete fixes this
            [_window.rootViewController.view performSelector:@selector(addSubview:) withObject:self.pinEntryViewController.view afterDelay:DELAY_KEYBOARD_DISMISSAL];
            [self performSelector:@selector(showStatusBar) withObject:nil afterDelay:DELAY_KEYBOARD_DISMISSAL];
        } else {
            [_window.rootViewController.view addSubview:self.pinEntryViewController.view];
        }
    }
    else {
        [self.tabViewController presentViewController:self.pinEntryViewController animated:YES completion:nil];
    }
    
    [self hideBusyView];
}

- (void)showStatusBar
{
    [[UIApplication sharedApplication] setStatusBarHidden:NO withAnimation:YES];
}

- (void)toggleSideMenu
{
    // If the sideMenu is not shown, show it
    if (_slidingViewController.currentTopViewPosition == ECSlidingViewControllerTopViewPositionCentered) {        
        [_slidingViewController anchorTopViewToRightAnimated:YES];
    }
    // If the sideMenu is shown, dismiss it
    else {
        [_slidingViewController resetTopViewAnimated:YES];
    }
    
    app.wallet.isFetchingTransactions = NO;
}

- (void)closeSideMenu
{
    // If the sideMenu is shown, dismiss it
    if (_slidingViewController.currentTopViewPosition != ECSlidingViewControllerTopViewPositionCentered) {
        [_slidingViewController resetTopViewAnimated:YES];
    }
}

- (void)showWelcome
{
    BCWelcomeView *welcomeView = [[BCWelcomeView alloc] init];
    [welcomeView.createWalletButton addTarget:self action:@selector(showCreateWallet:) forControlEvents:UIControlEventTouchUpInside];
    [welcomeView.existingWalletButton addTarget:self action:@selector(showPairWallet:) forControlEvents:UIControlEventTouchUpInside];
    [welcomeView.recoverWalletButton addTarget:self action:@selector(showRecoverWallet:) forControlEvents:UIControlEventTouchUpInside];
    
    [app showModalWithContent:welcomeView closeType:ModalCloseTypeNone showHeader:NO headerText:nil onDismiss:nil onResume:nil];
}

- (void)showHdUpgradeIfAppropriate
{
    NSString *bundleShortVersionString = [[NSBundle mainBundle] infoDictionary][INFO_PLIST_KEY_CFBUNDLE_SHORT_VERSION_STRING];
    
    if (![app.wallet didUpgradeToHd] && ![[[NSUserDefaults standardUserDefaults] valueForKey:USER_DEFAULTS_KEY_BUNDLE_VERSION_STRING] isEqualToString:bundleShortVersionString] && !self.pinEntryViewController && !_settingsNavigationController) {
        [[NSUserDefaults standardUserDefaults] setValue:bundleShortVersionString forKey:USER_DEFAULTS_KEY_BUNDLE_VERSION_STRING];
        [[NSUserDefaults standardUserDefaults] synchronize];
        [self showHdUpgrade];
    }
}

- (void)showHdUpgrade
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:STORYBOARD_NAME_UPGRADE bundle: nil];
    UpgradeViewController *upgradeViewController = [storyboard instantiateViewControllerWithIdentifier:VIEW_CONTROLLER_NAME_UPGRADE];
    upgradeViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_tabViewController presentViewController:upgradeViewController animated:YES completion:nil];
}

- (void)showCreateWallet:(id)sender
{
    [app showModalWithContent:createWalletView closeType:ModalCloseTypeBack headerText:BC_STRING_CREATE_NEW_WALLET];
    createWalletView.isRecoveringWallet = NO;
}

- (void)showPairWallet:(id)sender
{
    [app showModalWithContent:pairingInstructionsView closeType:ModalCloseTypeBack headerText:BC_STRING_AUTOMATIC_PAIRING];
    scanPairingCodeButton.titleEdgeInsets = WELCOME_VIEW_BUTTON_EDGE_INSETS;
    scanPairingCodeButton.titleLabel.adjustsFontSizeToFitWidth = YES;
    manualPairButton.titleEdgeInsets = WELCOME_VIEW_BUTTON_EDGE_INSETS;
    manualPairButton.titleLabel.adjustsFontSizeToFitWidth = YES;
}

- (void)showRecoverWallet:(id)sender
{
    UIAlertController *recoveryWarningAlert = [UIAlertController alertControllerWithTitle:BC_STRING_RECOVER_FUNDS message:BC_STRING_RECOVER_FUNDS_ONLY_IF_FORGOT_CREDENTIALS preferredStyle:UIAlertControllerStyleAlert];
    [recoveryWarningAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        [app showModalWithContent:createWalletView closeType:ModalCloseTypeBack headerText:BC_STRING_RECOVER_FUNDS];
        createWalletView.isRecoveringWallet = YES;
    }]];
    [recoveryWarningAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
    [self.window.rootViewController presentViewController:recoveryWarningAlert animated:YES completion:nil];
}

- (IBAction)manualPairClicked:(id)sender
{
    [self showModalWithContent:manualPairView closeType:ModalCloseTypeBack headerText:BC_STRING_MANUAL_PAIRING];
    self.wallet.twoFactorInput = nil;
    [manualPairView clearPasswordTextField];
}

- (void)reloadTransactionFilterLabel
{
#ifdef ENABLE_TRANSACTION_FILTERING
    if ([app.wallet didUpgradeToHd] && ([app.wallet hasLegacyAddresses] || [app.wallet getActiveAccountsCount] >= 2) && self.filterIndex != FILTER_INDEX_ALL) {
        app.mainLogoImageView.hidden = YES;
        if (_tabViewController.activeViewController == _transactionsViewController) {
            [_transactionsViewController showFilterLabel];
        } else {
            [_transactionsViewController hideFilterLabel];
        }
    } else {
        [_transactionsViewController hideFilterLabel];
        app.mainLogoImageView.hidden = _tabViewController.activeViewController == _transactionsViewController ? NO : YES;
    }
#endif
}

#pragma mark - Actions

- (IBAction)menuClicked:(id)sender
{
    if (_sendViewController) {
        [_sendViewController hideKeyboard];
    }
    [self toggleSideMenu];
}

- (IBAction)accountsAndAddressesClicked:(id)sender
{
    [app showAccountsAndAddresses];
}

- (IBAction)accountSettingsClicked:(id)sender
{
    [app showSettings];
}

- (IBAction)securityCenterClicked:(id)sender
{
    [app showSecurityCenter];
}

- (IBAction)supportClicked:(id)sender
{
    [app showSupport];
}

- (void)validatePINOptionally
{
    PEPinEntryController *pinVerifyPINOptionalController = [PEPinEntryController pinVerifyControllerClosable];
    pinVerifyPINOptionalController.pinDelegate = self;
    pinVerifyPINOptionalController.navigationBarHidden = YES;
    
    PEViewController *peViewController = (PEViewController *)[[pinVerifyPINOptionalController viewControllers] objectAtIndex:0];
    peViewController.cancelButton.hidden = NO;
    [peViewController.cancelButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    
    self.pinEntryViewController = pinVerifyPINOptionalController;
    
    peViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    
    [self.tabViewController dismissViewControllerAnimated:YES completion:nil];
    
    if (self.wallet.isSyncing) {
        [self showBusyViewWithLoadingText:BC_STRING_LOADING_SYNCING_WALLET];
    }
    
    [_window.rootViewController.view addSubview:self.pinEntryViewController.view];
}

- (void)changePIN
{
    PEPinEntryController *pinChangeController = [PEPinEntryController pinChangeController];
    pinChangeController.pinDelegate = self;
    pinChangeController.navigationBarHidden = YES;

    PEViewController *peViewController = (PEViewController *)[[pinChangeController viewControllers] objectAtIndex:0];
    peViewController.cancelButton.hidden = NO;
    [peViewController.cancelButton addTarget:self action:@selector(showSettings) forControlEvents:UIControlEventTouchUpInside];
    
    self.pinEntryViewController = pinChangeController;

    peViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [self.tabViewController dismissViewControllerAnimated:YES completion:nil];

    [_window.rootViewController.view addSubview:self.pinEntryViewController.view];
}

- (void)clearPin
{
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_ENCRYPTED_PIN_PASSWORD];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_PASSWORD_PART_HASH];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_PIN_KEY];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

- (void)closePINModal:(BOOL)animated
{
    // There are two different ways the pinModal is displayed: as a subview of tabViewController (on start) and as a viewController. This checks which one it is and dismisses accordingly
    if ([self.pinEntryViewController.view isDescendantOfView:_window.rootViewController.view]) {
        if (animated) {
            [UIView animateWithDuration:ANIMATION_DURATION animations:^{
                self.pinEntryViewController.view.alpha = 0;
            } completion:^(BOOL finished) {
                [self.pinEntryViewController.view removeFromSuperview];
            }];
        }
        else {
            [self.pinEntryViewController.view removeFromSuperview];
        }
    } else {
        [_tabViewController dismissViewControllerAnimated:animated completion:^{ }];
    }
    
    self.pinEntryViewController = nil;
}

- (IBAction)logoutClicked:(id)sender
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_LOGOUT
                                                    message:BC_STRING_REALLY_LOGOUT
                                                   delegate:self
                                          cancelButtonTitle:BC_STRING_CANCEL
                                          otherButtonTitles:BC_STRING_OK, nil];
    
    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        // Actually log out
        if (buttonIndex == 1) {
            [self logoutAndShowPasswordModal];
        }
    };
    
    [alert show];
}

- (void)logoutAndShowPasswordModal
{
    [self clearPin];
    [self.sendViewController clearToAddressAndAmountFields];
    [self logout];
    [self closeSideMenu];
    [self showPasswordModal];
}

- (void)confirmForgetWalletWithBlock:(void (^)(UIAlertView *alertView, NSInteger buttonIndex))tapBlock
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_WARNING
                                                    message:BC_STRING_FORGET_WALLET_DETAILS
                                                   delegate:self
                                          cancelButtonTitle:BC_STRING_CANCEL
                                          otherButtonTitles:BC_STRING_FORGET_WALLET, nil];
    alert.tapBlock = tapBlock;
    
    [alert show];
}

- (IBAction)forgetWalletClicked:(id)sender
{
    void (^confirmForgetWalletBlock)(UIAlertView *alertView, NSInteger buttonIndex) = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        // Forget Wallet Cancelled
        if (buttonIndex == 0) {
        }
        // Forget Wallet Confirmed
        else if (buttonIndex == 1) {
            DLog(@"forgetting wallet");
            [app closeModalWithTransition:kCATransitionFade];
            [self forgetWallet];
            [app showWelcome];
        }
    };
    
    if ([mainPasswordTextField isFirstResponder]) {
        [mainPasswordTextField resignFirstResponder];
        [self performSelector:@selector(confirmForgetWalletWithBlock:) withObject:confirmForgetWalletBlock afterDelay:DELAY_KEYBOARD_DISMISSAL];
    } else {
        [self confirmForgetWalletWithBlock:confirmForgetWalletBlock];
    }
}

- (IBAction)receiveCoinClicked:(UIButton *)sender
{
    if (!_receiveViewController) {
        _receiveViewController = [[ReceiveCoinsViewController alloc] initWithNibName:NIB_NAME_RECEIVE_COINS bundle:[NSBundle mainBundle]];
    }
    
    [_tabViewController setActiveViewController:_receiveViewController animated:TRUE index:2];
}

- (IBAction)transactionsClicked:(UIButton *)sender
{
    [_tabViewController setActiveViewController:_transactionsViewController animated:TRUE index:1];
}

- (IBAction)sendCoinsClicked:(UIButton *)sender
{
    [self showSendCoins];
}

- (IBAction)merchantClicked:(UIButton *)sender
{
    if (!_merchantViewController) {
        _merchantViewController = [[MerchantMapViewController alloc] initWithNibName:NIB_NAME_MERCHANT_MAP_VIEW bundle:[NSBundle mainBundle]];
    }
    
    _merchantViewController.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    [_tabViewController presentViewController:_merchantViewController animated:YES completion:nil];
}

-(IBAction)QRCodebuttonClicked:(id)sender
{
    if (!_sendViewController) {
        _sendViewController = [[SendViewController alloc] initWithNibName:NIB_NAME_SEND_COINS bundle:[NSBundle mainBundle]];
    }
    [_sendViewController QRCodebuttonClicked:sender];
}

- (IBAction)mainPasswordClicked:(id)sender
{
    [self showBusyViewWithLoadingText:BC_STRING_LOADING_DOWNLOADING_WALLET];
    [mainPasswordTextField resignFirstResponder];
    [self performSelector:@selector(loginMainPassword) withObject:nil afterDelay:DELAY_KEYBOARD_DISMISSAL];
}

- (void)loginMainPassword
{
    NSString *password = [mainPasswordTextField.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    if (password.length == 0) {
        [app standardNotify:BC_STRING_NO_PASSWORD_ENTERED];
        [self hideBusyView];
        return;
    }
    
    if (![self checkInternetConnection]) {
        [self hideBusyView];
        return;
    }
    
    NSString *guid = [self guid];
    NSString *sharedKey = [self sharedKey];
    
    if (guid && sharedKey && password) {
        [self.wallet loadWalletWithGuid:guid sharedKey:sharedKey password:password];
        
        self.wallet.delegate = self;
    } else {
        
        if (!guid) {
            DLog(@"failed to retrieve GUID from Keychain");
        }
        
        if (!sharedKey) {
            DLog(@"failed to retrieve sharedKey from Keychain");
        }
        
        if (guid && !sharedKey) {
            DLog(@"!!! Failed to retrieve sharedKey from Keychain but was able to retreive GUID ???");
        }
        
        [self failedToObtainValuesFromKeychain];
        
        [self hideBusyView];
    }
    
    mainPasswordTextField.text = nil;
}

- (void)authenticateWithTouchID
{
    self.pinEntryViewController.view.userInteractionEnabled = NO;
    
    LAContext *context = [[LAContext alloc] init];
    context.localizedFallbackTitle = @"";
    
    NSError *error = nil;
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        [context evaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics
                localizedReason:BC_STRING_TOUCH_ID_AUTHENTICATE
                          reply:^(BOOL success, NSError *error) {
                              
                              self.pinEntryViewController.view.userInteractionEnabled = YES;
                              
                              if (error) {
                                  if (error.code != kLAErrorUserCancel &&
                                      error.code != kLAErrorSystemCancel &&
                                      error.code != kLAErrorUserFallback) {
                                      
                                      UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:BC_STRING_TOUCH_ID_ERROR_VERIFYING_IDENTITY preferredStyle:UIAlertControllerStyleAlert];
                                      [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
                                      dispatch_async(dispatch_get_main_queue(), ^{
                                          [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                                      });
                                  }
                                  return;
                              }
                              
                              if (success) {
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [self showVerifyingBusyViewWithTimer:30.0];
                                  });
                                  NSString * pinKey = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_PIN_KEY];
                                  NSString * pin = [self pinFromKeychain];
                                  if (!pin) {
                                      [self failedToObtainValuesFromKeychain];
                                      return;
                                  }
                                  // DLog(@"touch ID is using PIN %@", pin);
                                  [app.wallet apiGetPINValue:pinKey pin:pin];
                                  
                              } else {
                                  UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:BC_STRING_TOUCH_ID_ERROR_WRONG_USER preferredStyle:UIAlertControllerStyleAlert];
                                  [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
                                  dispatch_async(dispatch_get_main_queue(), ^{
                                      [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
                                  });
                                  return;
                              }

                          }];
        
    } else {

        self.pinEntryViewController.view.userInteractionEnabled = YES;
        
        NSString *errorString;
        if (error.code == LAErrorTouchIDNotAvailable) {
            errorString = BC_STRING_TOUCH_ID_ERROR_NOT_AVAILABLE;
        } else if (error.code == LAErrorTouchIDNotEnrolled) {
            errorString = BC_STRING_TOUCH_ID_ERROR_MUST_ENABLE;
        } else if (error.code == LAErrorTouchIDLockout) {
            errorString = BC_STRING_TOUCH_ID_ERROR_LOCKED;
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:NO forKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:errorString preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.window.rootViewController presentViewController:alert animated:YES completion:nil];
        });
        return;
    }
}

- (NSString *)checkForTouchIDAvailablility
{
    LAContext *context = [[LAContext alloc] init];
    
    NSError *error = nil;
    if ([context canEvaluatePolicy:LAPolicyDeviceOwnerAuthenticationWithBiometrics error:&error]) {
        return nil;
    } else {
        if (error.code == LAErrorTouchIDNotAvailable) {
            return BC_STRING_TOUCH_ID_ERROR_NOT_AVAILABLE;
        } else if (error.code == LAErrorTouchIDNotEnrolled) {
            return BC_STRING_TOUCH_ID_ERROR_MUST_ENABLE;
        } else if (error.code == LAErrorTouchIDLockout) {
            return BC_STRING_TOUCH_ID_ERROR_LOCKED;
        }
        
        return BC_STRING_TOUCH_ID_ERROR_NOT_AVAILABLE;
        DLog(@"%@", [NSString stringWithFormat:BC_STRING_TOUCH_ID_ERROR_UNKNOWN_ARGUMENT, (long)error.code]);
    }
}

- (void)disabledTouchID
{
    [self removePinFromKeychain];
}

- (void)verifyTwoFactorSMS
{
    [manualPairView verifyTwoFactorSMS];
}

- (void)verifyTwoFactorGoogle
{
    [manualPairView verifyTwoFactorGoogle];
}

- (void)verifyTwoFactorYubiKey
{
    [manualPairView verifyTwoFactorYubiKey];
}

-(void)rateApp {
    
    [[UIApplication sharedApplication] openURL:[NSURL URLWithString:[APP_STORE_LINK_PREFIX stringByAppendingString:APP_STORE_ID]]];
}

#pragma mark - Pin Entry Delegates

- (void)pinEntryController:(PEPinEntryController *)c shouldAcceptPin:(NSUInteger)_pin callback:(void(^)(BOOL))callback
{
    self.lastEnteredPIN = _pin;
    
    // TODO does this ever happen?
    if (!app.wallet) {
        assert(1 == 2);
        [self askIfUserWantsToResetPIN];
        return;
    }
    
    NSString * pinKey = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_PIN_KEY];
    NSString * pin = [NSString stringWithFormat:@"%lu", (unsigned long)_pin];
    
    [self showVerifyingBusyViewWithTimer:30.0];
    
#ifdef TOUCH_ID_ENABLED
    if (self.pinEntryViewController.verifyOptional) {
        [self setPINInKeychain:pin];
    }
#endif
    
    [app.wallet apiGetPINValue:pinKey pin:pin];
    
    self.pinViewControllerCallback = callback;
}

- (void)showPinErrorWithMessage:(NSString *)message
{
    DLog(@"Pin error: %@", message);
    
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_ERROR
                                                    message:message
                                                   delegate:nil
                                          cancelButtonTitle:BC_STRING_OK
                                          otherButtonTitles:nil];
    
    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        // Reset the pin entry field
        [self hideBusyView];
        [self.pinEntryViewController reset];
    };
    
    [alert show];
}

- (void)askIfUserWantsToResetPIN {
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_PIN_VALIDATION_ERROR
                                                    message:BC_STRING_PIN_VALIDATION_ERROR_DETAIL
                                                   delegate:self
                                          cancelButtonTitle:BC_STRING_ENTER_PASSWORD
                                          otherButtonTitles:RETRY_VALIDATION, nil];
    
    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        if (buttonIndex == 0) {
            [self closePINModal:YES];
            
            [self showPasswordModal];
        } else if (buttonIndex == 1) {
            [self pinEntryController:self.pinEntryViewController shouldAcceptPin:self.lastEnteredPIN callback:self.pinViewControllerCallback];
        }
    };
    
    [alert show];
    
}

- (void)didFailGetPinTimeout
{
    [self showPinErrorWithMessage:BC_STRING_TIMED_OUT];
}

- (void)didFailGetPinNoResponse
{
    [self showPinErrorWithMessage:BC_STRING_INCORRECT_PIN_RETRY];
}

- (void)didFailGetPinInvalidResponse
{
    [self showPinErrorWithMessage:BC_STRING_INVALID_RESPONSE];
}

- (void)didGetPinResponse:(NSDictionary*)dictionary
{
    [self hideBusyView];
    
    NSNumber * code = [dictionary objectForKey:DICTIONARY_KEY_CODE]; //This is a status code from the server
    NSString * error = [dictionary objectForKey:DICTIONARY_KEY_ERROR]; //This is an error string from the server or nil
    NSString * success = [dictionary objectForKey:DICTIONARY_KEY_SUCCESS]; //The PIN decryption value from the server
    NSString * encryptedPINPassword = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_ENCRYPTED_PIN_PASSWORD];
    
    BOOL pinSuccess = FALSE;
    
    // Incorrect pin
    if (code == nil) {
        [app standardNotify:[NSString stringWithFormat:BC_STRING_INCORRECT_PIN_RETRY]];
    }
    // Pin retry limit exceeded
    else if ([code intValue] == PIN_API_STATUS_CODE_DELETED) {
        
        [app standardNotify:BC_STRING_PIN_VALIDATION_CANNOT_BE_COMPLETED];
        
        [self clearPin];
            
        [self logout];
            
        [self showPasswordModal];
        
        [self closePINModal:YES];

    }
    // Incorrect pin
    else if ([code integerValue] == PIN_API_STATUS_PIN_INCORRECT) {
        
        if (error == nil) {
            error = @"PIN Code Incorrect. Unknown Error Message.";
        }
        
        [app standardNotify:error];
    }
    // Pin was accepted
    else if ([code intValue] == PIN_API_STATUS_OK) {
        
#ifdef TOUCH_ID_ENABLED
        if (self.pinEntryViewController.verifyOptional) {
            [[NSUserDefaults standardUserDefaults] setBool:YES forKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED];
            [[NSUserDefaults standardUserDefaults] synchronize];
            [self closePINModal:YES];
            [self showSettings];
            return;
        }
#endif
        // This is for change PIN - verify the password first, then show the enter screens
        if (self.pinEntryViewController.verifyOnly == NO) {
            if (self.pinViewControllerCallback) {
                self.pinViewControllerCallback(YES);
                self.pinViewControllerCallback = nil;
            }
            
            return;
        }
        
        // Initial PIN setup ?
        if ([success length] == 0) {
            [app standardNotify:BC_STRING_PIN_RESPONSE_OBJECT_SUCCESS_LENGTH_0];
            [self askIfUserWantsToResetPIN];
            return;
        }
        
        NSString *decrypted = [app.wallet decrypt:encryptedPINPassword password:success pbkdf2_iterations:PIN_PBKDF2_ITERATIONS];
        
        if ([decrypted length] == 0) {
            [app standardNotify:BC_STRING_DECRYPTED_PIN_PASSWORD_LENGTH_0];
            [self askIfUserWantsToResetPIN];
            return;
        }
        
        NSString *guid = [self guid];
        NSString *sharedKey = [self sharedKey];
        
        if (guid && sharedKey) {
            [self.wallet loadWalletWithGuid:guid sharedKey:sharedKey password:decrypted];
        } else {
            
            if (!guid) {
                DLog(@"failed to retrieve GUID from Keychain");
            }
            
            if (!sharedKey) {
                DLog(@"failed to retrieve sharedKey from Keychain");
            }
            
            if (guid && !sharedKey) {
                DLog(@"!!! Failed to retrieve sharedKey from Keychain but was able to retreive GUID ???");
            }

            [self failedToObtainValuesFromKeychain];
        }
        
        [self closePINModal:YES];
        
        pinSuccess = TRUE;

    }
    // Unknown error
    else {
        [self askIfUserWantsToResetPIN];
    }
    
    if (self.pinViewControllerCallback) {
        self.pinViewControllerCallback(pinSuccess);
        self.pinViewControllerCallback = nil;
    }
    
#ifdef TOUCH_ID_ENABLED
    if (!pinSuccess && self.pinEntryViewController.verifyOptional) {
        [self removePinFromKeychain];
    }
#endif
}

- (void)didFailPutPin:(NSString*)value
{
    [self hideBusyView];
    
    [app standardNotify:value];
    
    [self reopenChangePIN];
}

- (void)reopenChangePIN
{
    [self closePINModal:NO];
    
    // Show the pin modal to enter a pin again
    self.pinEntryViewController = [PEPinEntryController pinCreateController];
    self.pinEntryViewController.navigationBarHidden = YES;
    self.pinEntryViewController.pinDelegate = self;
    
    if (self.isPinSet) {
        self.pinEntryViewController.inSettings = YES;
    }

    [_window.rootViewController.view addSubview:self.pinEntryViewController.view];
}

- (void)didPutPinSuccess:(NSDictionary*)dictionary
{
    [self hideBusyView];
    
    if (!app.wallet.password) {
        [self didFailPutPin:BC_STRING_CANNOT_SAVE_PIN_CODE_WHILE];
        return;
    }
    
    NSNumber * code = [dictionary objectForKey:DICTIONARY_KEY_CODE]; //This is a status code from the server
    NSString * error = [dictionary objectForKey:DICTIONARY_KEY_ERROR]; //This is an error string from the server or nil
    NSString * key = [dictionary objectForKey:DICTIONARY_KEY_KEY]; //This is our pin code lookup key
    NSString * value = [dictionary objectForKey:DICTIONARY_KEY_VALUE]; //This is our encryption string
    
    if (error != nil) {
        [self didFailPutPin:error];
    } else if (code == nil || [code intValue] != PIN_API_STATUS_OK) {
        [self didFailPutPin:[NSString stringWithFormat:BC_STRING_INVALID_STATUS_CODE_RETURNED, code]];
    } else if ([key length] == 0 || [value length] == 0) {
        [self didFailPutPin:BC_STRING_PIN_RESPONSE_OBJECT_KEY_OR_VALUE_LENGTH_0];
    } else {
        
        if (self.pinEntryViewController.inSettings) {
            [self showSettings];
        }
        //Encrypt the wallet password with the random value
        NSString * encrypted = [app.wallet encrypt:app.wallet.password password:value pbkdf2_iterations:PIN_PBKDF2_ITERATIONS];
        
        //Store the encrypted result and discard the value
        value = nil;
        
        if (!encrypted) {
            [self didFailPutPin:BC_STRING_PIN_ENCRYPTED_STRING_IS_NIL];
            return;
        }
        
        [[NSUserDefaults standardUserDefaults] setValue:encrypted forKey:USER_DEFAULTS_KEY_ENCRYPTED_PIN_PASSWORD];
        [[NSUserDefaults standardUserDefaults] setValue:[[app.wallet.password SHA256] substringToIndex:MIN([app.wallet.password length], 5)] forKey:USER_DEFAULTS_KEY_PASSWORD_PART_HASH];
        [[NSUserDefaults standardUserDefaults] setValue:key forKey:USER_DEFAULTS_KEY_PIN_KEY];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        // Update your info to new pin code
        [self closePINModal:YES];
        
        UIAlertView *alertViewSavedPINSuccessfully = [[UIAlertView alloc] initWithTitle:BC_STRING_SUCCESS message:BC_STRING_PIN_SAVED_SUCCESSFULLY delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles:nil];
        alertViewSavedPINSuccessfully.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
            [self showHdUpgradeIfAppropriate];
        };
        [alertViewSavedPINSuccessfully show];
    }
}

- (void)pinEntryController:(PEPinEntryController *)c willChangeToNewPin:(NSUInteger)_pin
{
    if (_pin == PIN_COMMON_CODE_1 ||
        _pin == PIN_COMMON_CODE_2 ||
        _pin == PIN_COMMON_CODE_3 ||
        _pin == PIN_COMMON_CODE_4) {
        
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_WARNING_TITLE message:BC_STRING_PIN_COMMON_CODE_WARNING_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CONTINUE style:UIAlertActionStyleDefault handler:nil]];
        [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_TRY_AGAIN style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self reopenChangePIN];
        }]];
        [c presentViewController:alert animated:YES completion:nil];
    }
    
    if (_pin == PIN_INVALID_CODE) {
        UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:BC_STRING_PLEASE_CHOOSE_ANOTHER_PIN preferredStyle:UIAlertControllerStyleAlert];
        [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            [self reopenChangePIN];
        }]];
        [c presentViewController:alert animated:YES completion:nil];
    }
}

- (void)pinEntryController:(PEPinEntryController *)c changedPin:(NSUInteger)_pin
{
    if (![app.wallet isInitialized] || !app.wallet.password) {
        [self didFailPutPin:BC_STRING_CANNOT_SAVE_PIN_CODE_WHILE];
        return;
    }
    
    NSString * pin = [NSString stringWithFormat:@"%lu", (unsigned long)_pin];
    
    [self showBusyViewWithLoadingText:BC_STRING_LOADING_VERIFYING];
    
    [self savePIN:pin];
}

- (void)savePIN:(NSString*)pin {
    uint8_t data[32];
    int err = 0;
    
    //32 Random bytes for key
    err = SecRandomCopyBytes(kSecRandomDefault, 32, data);
    if(err != noErr)
        @throw [NSException exceptionWithName:@"..." reason:@"..." userInfo:nil];
    
    NSString * key = [[[NSData alloc] initWithBytes:data length:32] hexadecimalString];
    
    //32 random bytes for value
    err = SecRandomCopyBytes(kSecRandomDefault, 32, data);
    if(err != noErr)
        @throw [NSException exceptionWithName:@"..." reason:@"..." userInfo:nil];
    
    NSString * value = [[[NSData alloc] initWithBytes:data length:32] hexadecimalString];
    
    [app.wallet pinServerPutKeyOnPinServerServer:key value:value pin:pin];
    
#ifdef TOUCH_ID_ENABLED
    if ([[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_TOUCH_ID_ENABLED]) {
        [self setPINInKeychain:pin];
    }
#endif
}

- (void)pinEntryControllerDidCancel:(PEPinEntryController *)c
{
    DLog(@"Pin change cancelled!");
    [self closePINModal:YES];
}

- (void)setPINInKeychain:(NSString *)pin
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_PIN accessGroup:nil];
    [keychain setObject:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    [keychain setObject:KEYCHAIN_KEY_PIN forKey:(__bridge id)kSecAttrAccount];
    [keychain setObject:[pin dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
}

- (NSString *)pinFromKeychain
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_PIN accessGroup:nil];
    NSData *pinData = [keychain objectForKey:(__bridge id)kSecValueData];
    NSString *pin = [[NSString alloc] initWithData:pinData encoding:NSUTF8StringEncoding];
    
    return pin.length == 0 ? nil : pin;
}

- (void)removePinFromKeychain
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_PIN accessGroup:nil];

    [keychain resetKeychainItem];
}

#pragma mark - GUID

- (NSString *)guid
{
    // Attempt to migrate guid from NSUserDefaults to KeyChain
    NSString *guidFromUserDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_GUID];
    if (guidFromUserDefaults) {
        [self setGuidInKeychain:guidFromUserDefaults];
        
        if ([self guidFromKeychain]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_GUID];
            [[NSUserDefaults standardUserDefaults] synchronize];

            // Remove all UIWebView cached data for users upgrading from older versions
            [[NSURLCache sharedURLCache] removeAllCachedResponses];
        } else {
            DLog(@"failed to set GUID in keychain");
            return guidFromUserDefaults;
        }
    }
    
    return [self guidFromKeychain];
}

- (void)setGuidInKeychain:(NSString *)guid
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_GUID accessGroup:nil];
    [keychain setObject:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    [keychain setObject:KEYCHAIN_KEY_GUID forKey:(__bridge id)kSecAttrAccount];
    [keychain setObject:[guid dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
}

- (NSString *)guidFromKeychain {
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_GUID accessGroup:nil];
    NSData *guidData = [keychain objectForKey:(__bridge id)kSecValueData];
    NSString *guid = [[NSString alloc] initWithData:guidData encoding:NSUTF8StringEncoding];
    
    return guid.length == 0 ? nil : guid;
}

- (void)removeGuidFromKeychain
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_GUID accessGroup:nil];
    
    [keychain resetKeychainItem];
}

- (NSString *)hashedGuid
{
    return [[self guid] SHA256];
}

#pragma mark - SharedKey

- (NSString *)sharedKey
{
    // Migrate sharedKey from NSUserDefaults (for users updating from old version)
    NSString *sharedKeyFromUserDefaults = [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_SHARED_KEY];
    if (sharedKeyFromUserDefaults) {
        [self setSharedKeyInKeychain:sharedKeyFromUserDefaults];
        
        if ([self sharedKeyFromKeychain]) {
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_SHARED_KEY];
            [[NSUserDefaults standardUserDefaults] synchronize];
        } else {
            DLog(@"!!! failed to set sharedKey in keychain ???");
            return sharedKeyFromUserDefaults;
        }
    }
    
    return [self sharedKeyFromKeychain];
}

- (NSString *)sharedKeyFromKeychain {
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_SHARED_KEY accessGroup:nil];
    NSData *sharedKeyData = [keychain objectForKey:(__bridge id)kSecValueData];
    NSString *sharedKey = [[NSString alloc] initWithData:sharedKeyData encoding:NSUTF8StringEncoding];
    
    return sharedKey.length == 0 ? nil : sharedKey;
}

- (void)setSharedKeyInKeychain:(NSString *)sharedKey
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_SHARED_KEY accessGroup:nil];
    [keychain setObject:(__bridge id)kSecAttrAccessibleWhenUnlockedThisDeviceOnly forKey:(__bridge id)kSecAttrAccessible];
    
    [keychain setObject:KEYCHAIN_KEY_SHARED_KEY forKey:(__bridge id)kSecAttrAccount];
    [keychain setObject:[sharedKey dataUsingEncoding:NSUTF8StringEncoding] forKey:(__bridge id)kSecValueData];
}

- (void)removeSharedKeyFromKeychain
{
    KeychainItemWrapper *keychain = [[KeychainItemWrapper alloc] initWithIdentifier:KEYCHAIN_KEY_SHARED_KEY accessGroup:nil];
    
    [keychain resetKeychainItem];
}

- (void)failedToObtainValuesFromKeychain
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:BC_STRING_FAILED_TO_LOAD_WALLET_TITLE
                                                    message:[NSString stringWithFormat:BC_STRING_ERROR_LOADING_WALLET_IDENTIFIER_FROM_KEYCHAIN]
                                                   delegate:nil
                                          cancelButtonTitle:BC_STRING_CLOSE_APP
                                          otherButtonTitles:nil];
    
    alert.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        // Close App
        UIApplication *app = [UIApplication sharedApplication];
        [app performSelector:@selector(suspend)];
    };
    [alert show];
}

#pragma mark - Format helpers

// Format amount in satoshi as NSString (with symbol)
- (NSString*)formatMoney:(uint64_t)value localCurrency:(BOOL)fsymbolLocal
{
    if (fsymbolLocal && latestResponse.symbol_local.conversion) {
        @try {
            NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(double)latestResponse.symbol_local.conversion]];
            
            return [latestResponse.symbol_local.symbol stringByAppendingString:[self.localCurrencyFormatter stringFromNumber:number]];
            
        } @catch (NSException * e) {
            DLog(@"Exception: %@", e);
        }
    } else if (latestResponse.symbol_btc) {
        NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:latestResponse.symbol_btc.conversion]];
        
        // mBTC display -> Always 2 decimal places
        if (latestResponse.symbol_btc.conversion == 100) {
            [_btcFormatter setMinimumFractionDigits:2];
        }
        // otherwise -> no min decimal places
        else {
            [_btcFormatter setMinimumFractionDigits:0];
        }
        
        NSString * string = [self.btcFormatter stringFromNumber:number];
        
        return [string stringByAppendingFormat:@" %@", latestResponse.symbol_btc.symbol];
    }
    
    NSDecimalNumber * number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:value] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:SATOSHI]];
    
    NSString * string = [self.btcFormatter stringFromNumber:number];
    
    return [string stringByAppendingString:@" BTC"];
}

- (NSString*)formatMoney:(uint64_t)value
{
    return [self formatMoney:value localCurrency:symbolLocal];
}

// Format amount in satoshi as NSString (without symbol)
- (NSString *)formatAmount:(uint64_t)amount localCurrency:(BOOL)localCurrency
{
    if (amount == 0) {
        return nil;
    }
    
    NSString *returnValue;
    
    if (localCurrency) {
        @try {
            NSDecimalNumber *number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:amount] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithDouble:(double)app.latestResponse.symbol_local.conversion]];
            
            app.localCurrencyFormatter.usesGroupingSeparator = NO;
            returnValue = [app.localCurrencyFormatter stringFromNumber:number];
            app.localCurrencyFormatter.usesGroupingSeparator = YES;
        } @catch (NSException * e) {
            DLog(@"Exception: %@", e);
        }
    } else {
        @try {
            NSDecimalNumber *number = [(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:amount] decimalNumberByDividingBy:(NSDecimalNumber*)[NSDecimalNumber numberWithLongLong:app.latestResponse.symbol_btc.conversion]];
            
            app.btcFormatter.usesGroupingSeparator = NO;
            returnValue = [app.btcFormatter stringFromNumber:number];
            app.btcFormatter.usesGroupingSeparator = YES;
        } @catch (NSException * e) {
            DLog(@"Exception: %@", e);
        }
    }
    
    return returnValue;
}

- (BOOL)stringHasBitcoinValue:(NSString *)string
{
    return string != nil && [string doubleValue] > 0;
}

#pragma mark - Mail compose delegate

- (void)mailComposeController:(MFMailComposeViewController*)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError*)error
{
    [self.tabViewController dismissViewControllerAnimated:YES completion:nil];
}

#pragma mark - State Checks

- (void)checkForNewInstall
{
    if (![[NSUserDefaults standardUserDefaults] boolForKey:USER_DEFAULTS_KEY_FIRST_RUN]) {
        
        if ([self guid] && [self sharedKey] && ![self isPinSet]) {
            [self alertUserAskingToUseOldKeychain];
        }
        
        [[NSUserDefaults standardUserDefaults] setBool:true forKey:USER_DEFAULTS_KEY_FIRST_RUN];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_HAS_SEEN_UPGRADE_TO_HD_SCREEN]) {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:USER_DEFAULTS_KEY_HAS_SEEN_UPGRADE_TO_HD_SCREEN];
    }
}

- (void)alertUserAskingToUseOldKeychain
{
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleLightContent animated:YES];
    UIAlertView *alertViewToKeepOldWallet = [[UIAlertView alloc] initWithTitle:BC_STRING_ASK_TO_USE_OLD_WALLET_TITLE message:BC_STRING_ASK_TO_USE_OLD_WALLET_MESSAGE delegate:nil cancelButtonTitle:BC_STRING_CREATE_NEW_WALLET otherButtonTitles: BC_STRING_LOGIN_EXISTING_WALLET, nil];
    alertViewToKeepOldWallet.tapBlock = ^(UIAlertView *alertView, NSInteger buttonIndex) {
        switch (buttonIndex) {
            case 0: {
                [self forgetWalletClicked:nil];
                return;
            }
            case 1: {
                return;
            }
        }
    };
    [alertViewToKeepOldWallet show];
}

- (void)alertUserOfCompromisedSecurity
{
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:BC_STRING_UNSAFE_DEVICE_TITLE message:BC_STRING_UNSAFE_DEVICE_MESSAGE delegate:nil cancelButtonTitle:BC_STRING_OK otherButtonTitles: nil];
    [alertView show];
}

- (void)checkAndWarnOnJailbrokenPhones
{
    if ([AppDelegate isUnsafe]) {
        [self alertUserOfCompromisedSecurity];
    }
}

+ (BOOL)isUnsafe
{
#if !(TARGET_IPHONE_SIMULATOR)
    
    if ([[NSFileManager defaultManager] fileExistsAtPath:UNSAFE_CHECK_PATH_CYDIA]){
        return YES;
    }else if([[NSFileManager defaultManager] fileExistsAtPath:UNSAFE_CHECK_PATH_MOBILE_SUBSTRATE]){
        return YES;
    }else if([[NSFileManager defaultManager] fileExistsAtPath:UNSAFE_CHECK_PATH_BIN_BASH]){
        return YES;
    }else if([[NSFileManager defaultManager] fileExistsAtPath:UNSAFE_CHECK_PATH_USR_SBIN_SSHD]){
        return YES;
    }else if([[NSFileManager defaultManager] fileExistsAtPath:UNSAFE_CHECK_PATH_ETC_APT]){
        return YES;
    }
    
    NSError *error;
    NSString *stringToBeWritten = @"TEST";
    [stringToBeWritten writeToFile:UNSAFE_CHECK_PATH_WRITE_TEST atomically:YES
                          encoding:NSUTF8StringEncoding error:&error];
    if(error == nil){
        return YES;
    } else {
        [[NSFileManager defaultManager] removeItemAtPath:UNSAFE_CHECK_PATH_WRITE_TEST error:nil];
    }
    
    if([[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:UNSAFE_CHECK_CYDIA_URL]]){
        return YES;
    }
#endif
    
    return NO;
}

- (BOOL)checkInternetConnection
{
    Reachability *reachability = [Reachability reachabilityForInternetConnection];
    if ([reachability currentReachabilityStatus] == NotReachable) {
        DLog(@"No Internet connection");
        [self showPinErrorWithMessage:BC_STRING_NO_INTERNET_CONNECTION];
        return NO;
    }
    return YES;
}

- (BOOL)isPinSet
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_PIN_KEY] != nil && [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_ENCRYPTED_PIN_PASSWORD] != nil;
}

- (AVCaptureDeviceInput *)getCaptureDeviceInput
{
    NSError *error;
    
    AVCaptureDevice *captureDevice = [AVCaptureDevice defaultDeviceWithMediaType:AVMediaTypeVideo];
    
    AVCaptureDeviceInput *input = [AVCaptureDeviceInput deviceInputWithDevice:captureDevice error:&error];
    if (!input) {
        // This should never happen - all devices we support (iOS 7+) have cameras
        DLog(@"QR code scanner problem: %@", [error localizedDescription]);
        
        if ([AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo] ==  AVAuthorizationStatusAuthorized) {
            [app standardNotifyAutoDismissingController:[error localizedDescription]];
        }
        else {
            UIAlertController *alert = [UIAlertController alertControllerWithTitle:BC_STRING_ENABLE_CAMERA_PERMISSIONS_ALERT_TITLE message:BC_STRING_ENABLE_CAMERA_PERMISSIONS_ALERT_MESSAGE preferredStyle:UIAlertControllerStyleAlert];
            [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_GO_TO_SETTINGS style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
                NSURL *settingsURL = [NSURL URLWithString:UIApplicationOpenSettingsURLString];
                [[UIApplication sharedApplication] openURL:settingsURL];
            }]];
            [alert addAction:[UIAlertAction actionWithTitle:BC_STRING_CANCEL style:UIAlertActionStyleCancel handler:nil]];
            
            if (self.topViewControllerDelegate) {
                [self.topViewControllerDelegate presentViewController:alert animated:YES completion:nil];
            } else {
                [_window.rootViewController presentViewController:alert animated:YES completion:nil];
            }
        }
    }
    return input;
}

#pragma mark API Endpoint Getters

// The debug endpoints are cleared from userDefaults in didFinishLaunching when ENABLE_DEBUG_MENUENABLE_DEBUG_MENU is undefined..so no need to check ENABLE_DEBUG_MENU in these getters
- (NSString *)serverURL
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL] == nil ? DEFAULT_WALLET_SERVER : [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_SERVER_URL];
}

- (NSString *)webSocketURL
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL] == nil ? DEFAULT_WEBSOCKET_SERVER : [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_WEB_SOCKET_URL];
}

- (NSString *)merchantURL
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_MERCHANT_URL] == nil ? DEFAULT_MERCHANT_URL : [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_MERCHANT_URL];
}

- (NSString *)apiURL
{
    return [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_API_URL] == nil ? DEFAULT_API_URL : [[NSUserDefaults standardUserDefaults] objectForKey:USER_DEFAULTS_KEY_DEBUG_API_URL];
}

@end

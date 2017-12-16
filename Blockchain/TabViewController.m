//
//  MainViewController.m
//  Tube Delays
//
//  Created by Ben Reeves on 10/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TabViewController.h"
#import "RootService.h"
#import "UIView+ChangeFrameAttribute.h"

@implementation TabViewcontroller

@synthesize oldViewController;
@synthesize activeViewController;
@synthesize contentView;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.assetSegmentedControl setTitle:BC_STRING_BITCOIN forSegmentAtIndex:0];
    [self.assetSegmentedControl setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:FONT_SIZE_SMALL]} forState:UIControlStateNormal];
    [self.assetSegmentedControl setTitle:BC_STRING_ETHER forSegmentAtIndex:1];
    [self.assetSegmentedControl addTarget:self action:@selector(assetSegmentedControlChanged) forControlEvents:UIControlEventValueChanged];
    
    balanceLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_EXTRA_EXTRA_LARGE];
    balanceLabel.adjustsFontSizeToFitWidth = YES;
    
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:app action:@selector(toggleSymbol)];
    [balanceLabel addGestureRecognizer:tapGesture];
    
    tabBar.delegate = self;
    
    // Default selected: transactions
    selectedIndex = TAB_TRANSACTIONS;
    
    [self setupTabButtons];
}

- (void)viewDidAppear:(BOOL)animated
{
    // Add side bar to swipe open the sideMenu
    if (!_menuSwipeRecognizerView) {
        _menuSwipeRecognizerView = [[UIView alloc] initWithFrame:CGRectMake(0, DEFAULT_HEADER_HEIGHT, 20, self.view.frame.size.height)];
        
        ECSlidingViewController *sideMenu = app.slidingViewController;
        [_menuSwipeRecognizerView addGestureRecognizer:sideMenu.panGesture];
        
        [self.view addSubview:_menuSwipeRecognizerView];
    }
}

- (void)setupTabButtons
{
    NSDictionary *tabButtons = @{BC_STRING_SEND:sendButton, BC_STRING_DASHBOARD:dashBoardButton, BC_STRING_TRANSACTIONS:homeButton, BC_STRING_REQUEST:receiveButton};
    
    for (UITabBarItem *button in [tabButtons allValues]) {
        NSString *label = [[tabButtons allKeysForObject:button] firstObject];
        button.title = label;
        button.image = [button.image imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        button.selectedImage = [button.selectedImage imageWithRenderingMode:UIImageRenderingModeAlwaysOriginal];
        [button setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_EXTRA_EXTRA_SMALL], NSForegroundColorAttributeName : COLOR_TEXT_DARK_GRAY} forState:UIControlStateNormal];
        [button setTitleTextAttributes:@{NSFontAttributeName : [UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:FONT_SIZE_EXTRA_EXTRA_EXTRA_SMALL], NSForegroundColorAttributeName : COLOR_BLOCKCHAIN_LIGHT_BLUE} forState:UIControlStateSelected];
    }
}

- (void)setActiveViewController:(UIViewController *)nviewcontroller
{
    [self setActiveViewController:nviewcontroller animated:NO index:selectedIndex];
}

- (void)setActiveViewController:(UIViewController *)nviewcontroller animated:(BOOL)animated index:(int)newIndex
{
    if (nviewcontroller == activeViewController)
        return;
    
    self.oldViewController = activeViewController;
    
    activeViewController = nviewcontroller;
    
    [self insertActiveView];
    
    self.oldViewController = nil;
    
    if (animated) {
        CATransition *animation = [CATransition animation];
        [animation setDuration:ANIMATION_DURATION];
        [animation setType:kCATransitionPush];
        [animation setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear]];
        
        if (newIndex > selectedIndex || (newIndex == selectedIndex && self.assetSegmentedControl.selectedSegmentIndex == AssetTypeEther))
            [animation setSubtype:kCATransitionFromRight];
        else
            [animation setSubtype:kCATransitionFromLeft];
        
        [[contentView layer] addAnimation:animation forKey:@"SwitchToView1"];
    }
    
    [self setSelectedIndex:newIndex];
    
    [self updateTopBarForIndex:newIndex];
}

- (void)insertActiveView
{
    if ([contentView.subviews count] > 0) {
        [[contentView.subviews objectAtIndex:0] removeFromSuperview];
    }
    
    [contentView addSubview:activeViewController.view];
    
    //Resize the View Sub Controller
    activeViewController.view.frame = CGRectMake(activeViewController.view.frame.origin.x, activeViewController.view.frame.origin.y, contentView.frame.size.width, activeViewController.view.frame.size.height);
    
    [activeViewController.view setNeedsLayout];
}

- (int)selectedIndex
{
    return selectedIndex;
}

- (void)setSelectedIndex:(int)nindex
{
    selectedIndex = nindex;
    
    tabBar.selectedItem = nil;

    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        tabBar.selectedItem = [[tabBar items] objectAtIndex:selectedIndex];
    });
    
    NSArray *titles = @[BC_STRING_SEND, BC_STRING_DASHBOARD, BC_STRING_TRANSACTIONS, BC_STRING_REQUEST];
    
    if (nindex < titles.count) {
        [self setTitleLabelText:[titles objectAtIndex:nindex]];
    } else {
        DLog(@"TabViewController Warning: no title found for selected index (array out of bounds)");
    }
}

- (void)updateTopBarForIndex:(int)newIndex
{
    titleLabel.hidden = NO;
    balanceLabel.hidden = YES;
    balanceLabel.userInteractionEnabled = NO;
    
    if (newIndex == TAB_SEND || newIndex == TAB_RECEIVE) {
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self.assetControlContainer changeYPosition:ASSET_CONTAINER_Y_POSITION_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET];
            [topBar changeHeight:TAB_HEADER_HEIGHT_DEFAULT - TAB_HEADER_HEIGHT_SMALL_OFFSET];
        }];
    } else if (newIndex == TAB_DASHBOARD || newIndex == TAB_TRANSACTIONS) {
        
        titleLabel.hidden = YES;
        balanceLabel.hidden = NO;

        NSDecimalNumber *btcBalance = [app.wallet btcDecimalBalance];
        NSDecimalNumber *ethBalance = [app.wallet ethDecimalBalance];
        
        if (newIndex == TAB_DASHBOARD) {
            [self showBalances];
            
            NSDecimalNumber *sum = [btcBalance decimalNumberByAdding:ethBalance];
            balanceLabel.text = [app.latestResponse.symbol_local.symbol stringByAppendingString:[app.localCurrencyFormatter stringFromNumber:sum]];
            
        } else if (newIndex == TAB_TRANSACTIONS) {
            [self.bannerPricesView removeFromSuperview];
            
            balanceLabel.userInteractionEnabled = YES;

            if (self.assetSegmentedControl.selectedSegmentIndex == AssetTypeBitcoin) {
                balanceLabel.text = [NSNumberFormatter formatMoneyWithLocalSymbol:[app.wallet getTotalActiveBalance]];
                [self showSelector];
            } else {
                balanceLabel.text = [NSNumberFormatter formatEthWithLocalSymbol:[app.wallet getEthBalanceTruncated] exchangeRate:app.tabControllerManager.latestEthExchangeRate];
                [self.bannerSelectorView removeFromSuperview];
            }
        }
        
        [UIView animateWithDuration:ANIMATION_DURATION animations:^{
            [self.assetControlContainer changeYPosition:ASSET_CONTAINER_Y_POSITION_DEFAULT];
            [topBar changeHeight:TAB_HEADER_HEIGHT_DEFAULT];
        }];
    }
}

- (void)addTapGestureRecognizerToTabBar:(UITapGestureRecognizer *)tapGestureRecognizer
{
    if (!self.tabBarGestureView) {
        self.tabBarGestureView = [[UIView alloc] initWithFrame:tabBar.bounds];
        self.tabBarGestureView.userInteractionEnabled = YES;
        [self.tabBarGestureView addGestureRecognizer:tapGestureRecognizer];
        [tabBar addSubview:self.tabBarGestureView];
    }
}

- (void)removeTapGestureRecognizerFromTabBar:(UITapGestureRecognizer *)tapGestureRecognizer
{
    [self.tabBarGestureView removeGestureRecognizer:tapGestureRecognizer];
    [self.tabBarGestureView removeFromSuperview];
    self.tabBarGestureView = nil;
}

- (void)tabBar:(UITabBar *)tabBar didSelectItem:(UITabBarItem *)item
{
    if (item == sendButton) {
        [app.tabControllerManager sendCoinsClicked:item];
    } else if (item == homeButton) {
        [app.tabControllerManager transactionsClicked:item];
    } else if (item == receiveButton) {
        [app.tabControllerManager receiveCoinClicked:item];
    } else if (item == dashBoardButton) {
        [app.tabControllerManager dashBoardClicked:item];
    }
}

- (void)updateBadgeNumber:(NSInteger)number forSelectedIndex:(int)index
{
    NSString *badgeString = number > 0 ? [NSString stringWithFormat:@"%lu", number] : nil;
    [[[tabBar items] objectAtIndex:index] setBadgeValue:badgeString];
}

- (void)setTitleLabelText:(NSString *)text
{
    titleLabel.text = text;
    titleLabel.hidden = NO;
}

- (void)selectAsset:(AssetType)assetType
{
    self.assetSegmentedControl.selectedSegmentIndex = assetType;
    
    [self assetSegmentedControlChanged];
}

- (void)assetSegmentedControlChanged
{
    AssetType asset = self.assetSegmentedControl.selectedSegmentIndex;
    
    [self.assetDelegate didSetAssetType:asset];
}

- (void)didFetchEthExchangeRate
{
    [self updateTopBarForIndex:self.selectedIndex];
}

- (void)showBalances
{
    if (!self.bannerPricesView) {
        
        CGFloat bannerViewHeight = bannerView.frame.size.height;
        CGFloat imageViewWidth = bannerViewHeight - 8;
        CGFloat imageViewHeightOffset = 20;
        CGFloat imageViewHeight = bannerViewHeight - imageViewHeightOffset;
        
        self.bannerPricesView = [[UIView alloc] initWithFrame:bannerView.bounds];
        
        UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:app action:@selector(toggleSymbol)];
        [self.bannerPricesView addGestureRecognizer:tapGesture];
        self.bannerPricesView.userInteractionEnabled = YES;
        
        UIImageView *btcIcon = [[UIImageView alloc] initWithFrame:CGRectMake(0, imageViewHeightOffset/2, imageViewWidth, imageViewHeight)];
        btcIcon.contentMode = UIViewContentModeScaleAspectFit;
        btcIcon.image = [UIImage imageNamed:@"bitcoin_white"];
        [self.bannerPricesView addSubview:btcIcon];
        
        CGFloat btcPriceLabelOriginX = btcIcon.frame.origin.x + btcIcon.frame.size.width;
        UILabel *btcPriceLabel = [[UILabel alloc] initWithFrame:CGRectMake(btcPriceLabelOriginX, 0, bannerView.bounds.size.width/2 - btcPriceLabelOriginX, bannerViewHeight)];
        btcPriceLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_EXTRALIGHT size:FONT_SIZE_SMALL];
        btcPriceLabel.textColor = [UIColor whiteColor];
        btcPriceLabel.text = CURRENCY_SYMBOL_BTC;
        
        [self.bannerPricesView addSubview:btcPriceLabel];
        self.btcPriceLabel = btcPriceLabel;
        
        UIImageView *etherIcon = [[UIImageView alloc] initWithFrame:CGRectMake(bannerView.bounds.size.width/2, imageViewHeightOffset/2, imageViewWidth, imageViewHeight)];
        etherIcon.contentMode = UIViewContentModeScaleAspectFit;
        etherIcon.image = [UIImage imageNamed:@"ether_white"];
        [self.bannerPricesView addSubview:etherIcon];
        
        CGFloat ethPriceLabelOriginX = etherIcon.frame.origin.x + etherIcon.frame.size.width;
        UILabel *ethPriceLabel = [[UILabel alloc] initWithFrame:CGRectMake(ethPriceLabelOriginX, 0, bannerView.frame.size.width - ethPriceLabelOriginX, bannerViewHeight)];
        ethPriceLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_EXTRALIGHT size:FONT_SIZE_SMALL];
        ethPriceLabel.textColor = [UIColor whiteColor];

        [self.bannerPricesView addSubview:ethPriceLabel];
        self.ethPriceLabel = ethPriceLabel;
    }
    
    [bannerView addSubview:self.bannerPricesView];

    if (app->symbolLocal) {
        self.ethPriceLabel.text = [NSNumberFormatter formatEthWithLocalSymbol:[app.wallet getEthBalance] exchangeRate:app.tabControllerManager.latestEthExchangeRate];
        self.btcPriceLabel.text = [NSNumberFormatter formatMoney:[app.wallet getTotalActiveBalance] localCurrency:YES];
    } else {
        self.ethPriceLabel.text = [NSString stringWithFormat:@"%@ %@", [app.wallet getEthBalanceTruncated], CURRENCY_SYMBOL_ETH];
        self.btcPriceLabel.text = [NSNumberFormatter formatMoney:[app.wallet getTotalActiveBalance] localCurrency:NO];
    }
    
    [self.bannerSelectorView removeFromSuperview];
}

- (void)showSelector
{
    if (!self.bannerSelectorView) {
        self.bannerSelectorView = [[UIView alloc] initWithFrame:bannerView.bounds];
        UIButton *selectorButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, bannerView.frame.size.width, bannerView.frame.size.height)];
        selectorButton.titleLabel.textColor = [UIColor whiteColor];
        selectorButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
        selectorButton.contentEdgeInsets = UIEdgeInsetsZero;
        selectorButton.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_EXTRALIGHT size:FONT_SIZE_SMALL];
        [selectorButton setTitle:BC_STRING_BITCOIN_BALANCES forState:UIControlStateNormal];
        [selectorButton setImage:[[UIImage imageNamed:@"back_chevron_icon"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];
        selectorButton.imageView.transform = CGAffineTransformMakeScale(-1, 1);
        selectorButton.tintColor = [UIColor whiteColor];
        
        UIButton *buttonForTitleWidth = [[UIButton alloc] initWithFrame:selectorButton.frame];
        buttonForTitleWidth.titleLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_EXTRALIGHT size:FONT_SIZE_SMALL];
        [buttonForTitleWidth setTitle:BC_STRING_BITCOIN_BALANCES forState:UIControlStateNormal];
        [buttonForTitleWidth sizeToFit];
        
        selectorButton.imageEdgeInsets = UIEdgeInsetsMake(0, -selectorButton.imageView.bounds.size.width + selectorButton.frame.size.width/2 + buttonForTitleWidth.frame.size.width/2 + 20, 0, 0);
        selectorButton.titleEdgeInsets = UIEdgeInsetsMake(0, -selectorButton.imageView.bounds.size.width, 0, 0);
        [selectorButton addTarget:self action:@selector(selectorButtonClicked) forControlEvents:UIControlEventTouchUpInside];
        [self.bannerSelectorView addSubview:selectorButton];
    }
    
    [bannerView addSubview:self.bannerSelectorView];
    [self.bannerPricesView removeFromSuperview];
}

- (void)selectorButtonClicked
{
    [self.assetDelegate selectorButtonClicked];
}

- (void)didSendEther
{
    [app closeAllModals];
    
    UIAlertController *successAlert = [UIAlertController alertControllerWithTitle:BC_STRING_SUCCESS message:BC_STRING_PAYMENT_SENT_ETHER preferredStyle:UIAlertControllerStyleAlert];
    [successAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:successAlert animated:YES completion:nil];
}

- (void)didErrorDuringEtherSend:(NSString *)error
{
    [app closeAllModals];
    
    UIAlertController *errorAlert = [UIAlertController alertControllerWithTitle:BC_STRING_ERROR message:error preferredStyle:UIAlertControllerStyleAlert];
    [errorAlert addAction:[UIAlertAction actionWithTitle:BC_STRING_OK style:UIAlertActionStyleCancel handler:nil]];
    [self presentViewController:errorAlert animated:YES completion:nil];
}

- (IBAction)qrCodeButtonClicked:(UIButton *)sender
{
    [self.assetDelegate qrCodeButtonClicked];
}

- (void)reloadSymbols
{
    [self updateTopBarForIndex:self.selectedIndex];
}

@end

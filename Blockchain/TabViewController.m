//
//  MainViewController.m
//  Tube Delays
//
//  Created by Ben Reeves on 10/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TabViewController.h"
#import "RootService.h"

@implementation TabViewcontroller

@synthesize oldViewController;
@synthesize activeViewController;
@synthesize contentView;

- (void)awakeFromNib
{
    [super awakeFromNib];
    
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
    NSDictionary *tabButtons = @{BC_STRING_SEND:sendButton, BC_STRING_OVERVIEW:homeButton, BC_STRING_REQUEST:receiveButton};
    
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
        
        if (newIndex > selectedIndex)
            [animation setSubtype:kCATransitionFromRight];
        else
            [animation setSubtype:kCATransitionFromLeft];
        
        [[contentView layer] addAnimation:animation forKey:@"SwitchToView1"];
    }
    
    [self setSelectedIndex:newIndex];
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
        [app sendCoinsClicked:item];
    } else if (item == homeButton) {
        [app transactionsClicked:item];
    } else if (item == receiveButton) {
        [app receiveCoinClicked:item];
    }
}

- (void)updateBadgeNumber:(NSInteger)number forSelectedIndex:(int)index
{
    NSString *badgeString = number > 0 ? [NSString stringWithFormat:@"%lu", number] : nil;
    [[[tabBar items] objectAtIndex:index] setBadgeValue:badgeString];
}

@end

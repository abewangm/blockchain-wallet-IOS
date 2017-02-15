//
//  MainViewController.m
//  Tube Delays
//
//  Created by Ben Reeves on 10/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "TabViewcontroller.h"
#import "RootService.h"

@implementation TabViewcontroller

@synthesize oldViewController;
@synthesize activeViewController;
@synthesize contentView;

- (void)awakeFromNib
{
    [super awakeFromNib];
    // Default selected: transactions
    selectedIndex = TAB_TRANSACTIONS;
    
    [self setupTabButtons];
    
    // Swipe between tabs for fun
    UISwipeGestureRecognizer *swipeLeft = [[UISwipeGestureRecognizer alloc] initWithTarget:app action:@selector(swipeLeft)];
    swipeLeft.direction = UISwipeGestureRecognizerDirectionLeft;
    UISwipeGestureRecognizer *swipeRight = [[UISwipeGestureRecognizer alloc] initWithTarget:app action:@selector(swipeRight)];
    swipeRight.direction = UISwipeGestureRecognizerDirectionRight;
    
    [contentView addGestureRecognizer:swipeLeft];
    [contentView addGestureRecognizer:swipeRight];
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
    CGFloat spacing = 2.0;
    
    NSDictionary *tabButtons = @{BC_STRING_SEND:sendButton, BC_STRING_TRANSACTIONS:homeButton, BC_STRING_RECEIVE:receiveButton};
    
    for (UIButton *button in [tabButtons allValues]) {
                
        NSString *label = [[tabButtons allKeysForObject:button] firstObject];
        [button setTitle:label forState:UIControlStateNormal];
        [button.titleLabel setFont:[UIFont fontWithName:FONT_MONTSERRAT_REGULAR size:10]];
        CGSize titleSize = [label sizeWithAttributes:@{NSFontAttributeName: button.titleLabel.font}];
        
        CGSize imageSize = button.imageView.image.size;
        button.imageEdgeInsets = UIEdgeInsetsMake(-(titleSize.height + spacing), 0, 0, -titleSize.width);
        
        button.titleEdgeInsets = UIEdgeInsetsMake(0, -imageSize.width, -(imageSize.height + spacing), 0);
        [button setTitleColor:COLOR_TEXT_DARK_GRAY forState:UIControlStateNormal];
        [button setTitleColor:COLOR_BLOCKCHAIN_LIGHT_BLUE forState:UIControlStateHighlighted];
        
        button.titleLabel.adjustsFontSizeToFitWidth = YES;
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
    
    sendButton.highlighted = NO;
    homeButton.highlighted = NO;
    receiveButton.highlighted = NO;
    sendButton.userInteractionEnabled = YES;
    homeButton.userInteractionEnabled = YES;
    receiveButton.userInteractionEnabled = YES;
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.1 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
    if (selectedIndex == TAB_SEND) {
        sendButton.highlighted = YES;
        sendButton.userInteractionEnabled = NO;
    }
    else if (selectedIndex == TAB_TRANSACTIONS) {
        homeButton.highlighted = YES;
        homeButton.userInteractionEnabled = NO;
    }
    else if (selectedIndex == TAB_RECEIVE) {
        receiveButton.highlighted = YES;
        receiveButton.userInteractionEnabled = NO;
    }
    });
}

@end

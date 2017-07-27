//
//  MainViewController.h
//  Tube Delays
//
//  Created by Ben Reeves on 10/11/2010.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

@interface TabViewcontroller : UIViewController <UITabBarDelegate> {
    IBOutlet UITabBarItem *sendButton;
    IBOutlet UITabBarItem *homeButton;
    IBOutlet UITabBarItem *receiveButton;
    IBOutlet UITabBar *tabBar;
	
	UIViewController *activeViewController;
	UIViewController *oldViewController;
    
	int selectedIndex;
}

@property(nonatomic, retain) UIViewController *activeViewController;
@property(nonatomic, retain) UIViewController *oldViewController;
@property(nonatomic, retain) IBOutlet UIView *contentView;
@property(nonatomic, retain) UIView *menuSwipeRecognizerView;
@property(nonatomic) UIView *tabBarGestureView;

- (void)setActiveViewController:(UIViewController *)nviewcontroller animated:(BOOL)animated index:(int)index;
- (void)addTapGestureRecognizerToTabBar:(UITapGestureRecognizer *)tapGestureRecognizer;
- (void)removeTapGestureRecognizerFromTabBar:(UITapGestureRecognizer *)tapGestureRecognizer;
- (int)selectedIndex;

@end

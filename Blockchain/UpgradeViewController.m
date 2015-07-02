//
//  UpgradeViewController.m
//  Blockchain
//
//  Created by Kevin Wu on 7/1/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "UpgradeViewController.h"

@interface UpgradeViewController ()
@property (weak, nonatomic) IBOutlet UIPageControl *pageControl;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UILabel *captionLabel;
@property (nonatomic) NSMutableArray *pageViewsMutableArray;

@end

@implementation UpgradeViewController

- (IBAction)cancelButtonTapped:(UIButton *)sender
{
    [[self presentingViewController] dismissViewControllerAnimated:YES completion:nil];
}

- (NSArray *)imageNamesArray
{
    return @[@"home_icon_hi", @"home_icon", @"lock_icon"];
}

- (NSArray *)captionLabelTextsArray
{
    return @[@"Create personalized accounts to help keep your wallet organized", @"Easy one time wallet backup keeps you in control of your funds", @"Anything you need to store, spend and receive your bitcoin"];
}

- (void)loadPage:(NSInteger)page
{
    if (page < 0 || page >= [self imageNamesArray].count) {
        return;
    }
    
    UIView *pageView = [self.pageViewsMutableArray objectAtIndex:page];
    
    if ((NSNull*)pageView == [NSNull null]) {
        CGRect frame = self.scrollView.bounds;
        frame.origin.x = frame.size.width * page;
        frame.origin.y = 0.0f;
        
        UIImage *image = [UIImage imageNamed:[[self imageNamesArray] objectAtIndex:page]];
        UIImageView *newPageView = [[UIImageView alloc] initWithImage:image];
        newPageView.contentMode = UIViewContentModeScaleAspectFit;
        newPageView.frame = frame;
        [self.scrollView addSubview:newPageView];
        [self.pageViewsMutableArray replaceObjectAtIndex:page withObject:newPageView];
    }
}

- (void)purgePage:(NSInteger)page {
    
    if (page < 0 || page >= [self imageNamesArray].count) {
        return;
    }
    
    UIView *pageView = [self.pageViewsMutableArray objectAtIndex:page];
    
    if ((NSNull*)pageView != [NSNull null]) {
        [pageView removeFromSuperview];
        [self.pageViewsMutableArray replaceObjectAtIndex:page withObject:[NSNull null]];
    }
}

- (void)loadVisiblePages
{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    NSInteger page = (NSInteger)floor((self.scrollView.contentOffset.x * 2.0f + pageWidth) / (pageWidth * 2.0f));
    
    self.pageControl.currentPage = page;
    
    NSInteger firstPage = page - 1;
    NSInteger lastPage = page + 1;
    
    for (NSInteger i = 0; i < firstPage; i++) {
        [self purgePage:i];
    }
    
    for (NSInteger i = firstPage; i <= lastPage; i++) {
        [self loadPage:i];
    }
    
    for (NSInteger i = lastPage+1; i < [self pageViewsMutableArray].count; i++) {
        [self purgePage:i];
    }
    
    self.captionLabel.text = [[self captionLabelTextsArray] objectAtIndex:self.pageControl.currentPage];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    self.pageControl.currentPage = 0;
    self.pageControl.numberOfPages = [[self imageNamesArray] count];
    
    self.pageViewsMutableArray = [[NSMutableArray alloc] init];
    for (int i = 0; i < [[self imageNamesArray] count]; i++) {
        [self.pageViewsMutableArray addObject:[NSNull null]];
    }
}

- (void)viewDidLayoutSubviews
{
    [super viewDidLayoutSubviews];
    
    CGSize pagesScrollViewSize = self.scrollView.frame.size;
    self.scrollView.contentSize = CGSizeMake(pagesScrollViewSize.width * [self pageViewsMutableArray].count, pagesScrollViewSize.height);
    self.upgradeWalletButton.clipsToBounds = YES;
    self.upgradeWalletButton.layer.cornerRadius = 20;
    
    [self loadVisiblePages];
}

#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    [self loadVisiblePages];
}

@end

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

@end

@implementation UpgradeViewController

- (NSArray *)imageNamesArray
{
    return @[@"image1", @"image2", @"image3"];
}

- (void)setupImages
{
    NSArray *imageNamesArray = [self imageNamesArray];
    for (int i = 0; i < [imageNamesArray count]; i++) {
        
        CGFloat scrollViewFrameWidth = self.scrollView.frame.size.width;
        
        CGRect frame = CGRectMake(scrollViewFrameWidth + scrollViewFrameWidth * i, self.scrollView.frame.origin.y, scrollViewFrameWidth, self.scrollView.frame.size.height);
        
        UIImageView *imageView = [[UIImageView alloc] initWithFrame:frame];
        imageView.image = [UIImage imageNamed:imageNamesArray[i]];
        [self.scrollView addSubview:imageView];
    }
}
            
- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

#pragma mark UIScrollView Delegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat pageWidth = self.scrollView.frame.size.width;
    int page = floor((self.scrollView.contentOffset.x - pageWidth/2)/pageWidth) + 1;
    self.pageControl.currentPage = page;
}

@end

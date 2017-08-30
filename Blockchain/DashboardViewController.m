//
//  DashboardViewController.m
//  Blockchain
//
//  Created by kevinwu on 8/23/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "DashboardViewController.h"
#import "SessionManager.h"

@interface CardsViewController ()
@property (nonatomic) UIScrollView *scrollView;
@property (nonatomic) UIView *contentView;
@end

@interface DashboardViewController ()

@end

@implementation DashboardViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    // This contentView can be any custom view - intended to be placed at the top of the scroll view, moved down when the cards view is present, and moved back up when the cards view is dismissed
    self.contentView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 320)];
    self.contentView.backgroundColor = [UIColor purpleColor];
    [self.scrollView addSubview:self.contentView];
}

- (void)reload
{
    [self reloadCards];
    
    NSURL *URL = [NSURL URLWithString:[URL_SERVER stringByAppendingString:CHARTS_URL_SUFFIX]];
    NSURLRequest *request = [NSURLRequest requestWithURL:URL];
    
    NSURLSessionDataTask *task = [[SessionManager sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error) {
            DLog(@"Error getting chart data - %@", [error localizedDescription]);
        } else {
            NSError *jsonError;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonError];
            // DLog(@"%@", jsonResponse);
        }
    }];
    
    [task resume];
}

@end

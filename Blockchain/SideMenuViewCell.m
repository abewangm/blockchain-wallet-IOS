//
//  SideMenuViewCell.m
//  Blockchain
//
//  Created by Mark Pfluger on 7/8/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

#import "SideMenuViewCell.h"

@implementation SideMenuViewCell

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(15, 15, 26, 26);
    self.imageView.contentMode = UIViewContentModeCenter;
    
    self.textLabel.frame = CGRectMake(55, 15, 200, 26);
    
    self.backgroundColor = [UIColor clearColor];
    self.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
    self.textLabel.textColor = [UIColor lightGrayColor];
    self.textLabel.highlightedTextColor = [UIColor whiteColor];
}

@end

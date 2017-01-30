//
//  SideMenuViewCell.m
//  Blockchain
//
//  Created by Mark Pfluger on 7/8/15.
//  Copyright (c) 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import "SideMenuViewCell.h"

@implementation SideMenuViewCell

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        _dotImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"backup_red_circle"]];
        [self.contentView addSubview:self.dotImageView];
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.imageView.frame = CGRectMake(15, 15, 26, 26);
    self.imageView.contentMode = UIViewContentModeCenter;

    if (self.detailTextLabel.text != nil) {
        self.textLabel.frame = CGRectMake(55, 10, 200, 21);
        self.detailTextLabel.frame = CGRectOffset(self.textLabel.frame, 0, 20);
    } else {
        self.textLabel.frame = CGRectMake(55, 15, 200, 26);
    }
    
    self.backgroundColor = [UIColor clearColor];
    self.textLabel.font = [UIFont boldSystemFontOfSize:17.0];
    self.textLabel.textColor = [UIColor lightGrayColor];
    self.textLabel.highlightedTextColor = [UIColor whiteColor];
    
    self.dotImageView.frame = CGRectMake(self.textLabel.frame.origin.x + self.textLabel.frame.size.width - 21, self.textLabel.frame.origin.y, 13, 13);
    self.dotImageView.center = CGPointMake(self.dotImageView.center.x, self.textLabel.center.y);
}

- (void)setShowDot:(BOOL)showDot
{
    _showDot = showDot;
    
    if (_showDot) {
        self.textLabel.frame = CGRectMake(55, 15, 179, 26);
        self.dotImageView.hidden = NO;
    } else {
        self.textLabel.frame = CGRectMake(55, 15, 200, 26);
        self.dotImageView.hidden = YES;
    }
}

@end

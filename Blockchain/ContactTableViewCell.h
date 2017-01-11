//
//  ContactTableViewCell.h
//  Blockchain
//
//  Created by Kevin Wu on 12/19/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Contact.h"

@interface ContactTableViewCell : UITableViewCell
@property (nonatomic) UIImageView *actionImageView;
@property (nonatomic) UILabel *mainLabel;

- (void)configureWithContact:(Contact *)contact actionRequired:(BOOL)actionRequired;
@end

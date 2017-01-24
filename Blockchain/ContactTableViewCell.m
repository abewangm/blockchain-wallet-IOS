//
//  ContactTableViewCell.m
//  Blockchain
//
//  Created by Kevin Wu on 12/19/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactTableViewCell.h"
@interface ContactTableViewCell()
@property (nonatomic) BOOL isSetup;
@end
@implementation ContactTableViewCell

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    return self;
}

- (void)configureWithContact:(Contact *)contact actionRequired:(BOOL)actionRequired
{
    if (self.isSetup) {
        self.actionImageView.hidden = !actionRequired;
        self.mainLabel.text = contact.name ? contact.name : contact.identifier;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return;
    }
    
    self.actionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, (self.frame.size.height - 13)/2, 13, 13)];
    [self.contentView addSubview:self.actionImageView];
    self.actionImageView.image = [UIImage imageNamed:@"backup_blue_circle"];
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    CGFloat mainLabelOriginX = self.actionImageView.frame.origin.x + self.actionImageView.frame.size.width + 8;
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainLabelOriginX, (self.frame.size.height - 30)/2, self.frame.size.width - mainLabelOriginX - 28, 30)];
    [self.contentView addSubview:self.mainLabel];
    self.mainLabel.text = contact.name ? contact.name : contact.identifier;
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    
    self.isSetup = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.accessoryType = UITableViewCellAccessoryNone;
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
    self.actionImageView.hidden = YES;
}

@end

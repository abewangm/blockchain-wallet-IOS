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
        self.mainLabel.text = contact.name ? contact.name : contact.identifier;
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return;
    }
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, (self.frame.size.height - 30)/2, self.frame.size.width - 20 - 28, 30)];
    [self.contentView addSubview:self.mainLabel];
    self.mainLabel.font = [UIFont fontWithName:FONT_MONTSERRAT_LIGHT size:15];
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
}

@end

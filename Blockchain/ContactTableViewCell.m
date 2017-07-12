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
        [self setTextWithContact:contact];
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return;
    }
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, (self.frame.size.height - 30)/2, self.frame.size.width - 20 - 28, 30)];
    [self.contentView addSubview:self.mainLabel];
    self.mainLabel.font = [UIFont systemFontOfSize:15];
    self.mainLabel.text = contact.name ? contact.name : contact.identifier;
    self.mainLabel.adjustsFontSizeToFitWidth = YES;
    
    [self setTextWithContact:contact];

    self.isSetup = YES;
}

- (void)setTextWithContact:(Contact *)contact
{
    NSString *name = contact.name ? : contact.identifier;
    self.mainLabel.text = contact.mdid ? name : [NSString stringWithFormat:@"%@ (%@)", name, BC_STRING_PENDING];
    self.mainLabel.textColor = contact.mdid ? COLOR_TEXT_DARK_GRAY : COLOR_LIGHT_GRAY;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.accessoryType = UITableViewCellAccessoryNone;
    self.textLabel.text = nil;
    self.detailTextLabel.text = nil;
}

@end

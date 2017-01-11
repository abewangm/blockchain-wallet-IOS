//
//  ContactTransactionTableViewCell.m
//  Blockchain
//
//  Created by kevinwu on 1/11/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

#import "ContactTransactionTableViewCell.h"
@interface ContactTransactionTableViewCell()
@property (nonatomic) BOOL isSetup;
@end
@implementation ContactTransactionTableViewCell

- (id)initWithTransaction:(ContactTransaction *)transaction style:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:reuseIdentifier];
    if (self) {
        self.transaction = transaction;
    }
    return self;
}

- (void)configureWithTransaction:(Transaction *)transaction actionRequired:(BOOL)actionRequired
{
    if (self.isSetup) {
        self.actionImageView.hidden = !actionRequired;
        self.mainLabel.text = @"test text";
        self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        return;
    }
    
    self.actionImageView = [[UIImageView alloc] initWithFrame:CGRectMake(15, (self.frame.size.height - 26)/2, 26, 26)];
    [self.contentView addSubview:self.actionImageView];
    self.actionImageView.image = [UIImage imageNamed:@"icon_support"];
    
    self.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    
    CGFloat mainLabelOriginX = self.actionImageView.frame.origin.x + self.actionImageView.frame.size.width + 8;
    self.mainLabel = [[UILabel alloc] initWithFrame:CGRectMake(mainLabelOriginX, (self.frame.size.height - 30)/2, self.frame.size.width - mainLabelOriginX - 28, 30)];
    [self.contentView addSubview:self.mainLabel];
    self.mainLabel.text = @"test text";
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

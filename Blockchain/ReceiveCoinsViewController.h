/*
 * 
 * Copyright (c) 2012, Ben Reeves. All rights reserved.
 *
 * This library is free software; you can redistribute it and/or
 * modify it under the terms of the GNU Lesser General Public
 * License as published by the Free Software Foundation; either
 * version 2.1 of the License, or (at your option) any later version.
 *
 * This library is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * Lesser General Public License for more details.
 *
 * You should have received a copy of the GNU Lesser General Public
 * License along with this library; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301  USA
 */

#import <UIKit/UIKit.h>
#import "Wallet.h"

@interface ReceiveCoinsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate> {
    IBOutlet UITableView * tableView;
    IBOutlet UIView * qrCodeModalView;
    IBOutlet UIImageView * qrCodeImageView;
    IBOutlet UIButton * archiveUnarchiveButton;
    IBOutlet UIView * tableFooterView;
    
    IBOutlet UIButton * depositButton;
    IBOutlet UIView * noaddressesView;
    
    //Label Address
    IBOutlet UIView * labelAddressView;
    IBOutlet UITextField * labelTextField;
    IBOutlet UILabel * labelAddressLabel;
}

@property(nonatomic, strong) NSArray * activeKeys;
@property(nonatomic, strong) NSArray * archivedKeys;
@property(nonatomic, strong) NSArray * otherKeys;

@property(nonatomic, strong) IBOutlet Wallet * wallet;

-(IBAction)labelAddressClicked:(id)sender;
-(IBAction)archiveAddressClicked:(id)sender;
-(IBAction)generateNewAddressClicked:(id)sender;
-(IBAction)qrCodeImageClicked:(id)sender;
-(IBAction)labelSaveClicked:(id)sender;
-(IBAction)depositClicked:(id)sender;

@end

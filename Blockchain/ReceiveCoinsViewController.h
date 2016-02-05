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

#import "Wallet.h"

@interface ReceiveCoinsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate, UITextFieldDelegate> {
    IBOutlet UITableView *tableView;
    IBOutlet UIImageView *qrCodeMainImageView;
    IBOutlet UIImageView *qrCodePaymentImageView;
    IBOutlet UIButton *moreActionsButton;
    
    // Label Address
    IBOutlet UIView *labelAddressView;
    IBOutlet UITextField *labelTextField;
    IBOutlet UILabel *labelAddressLabel;
    IBOutlet UIView *requestCoinsView;
    
    IBOutlet UILabel *optionsTitleLabel;
    
    // Amount buttons and field
    IBOutlet UITextField *entryField;
    IBOutlet UILabel *btcLabel;
    IBOutlet UITextField *btcAmountField;
    IBOutlet UILabel *fiatLabel;
    IBOutlet UITextField *fiatAmountField;
    
    // Keyboard accessory view
    IBOutlet UIView *amountKeyboardAccessoryView;
}

@property(nonatomic, strong) NSArray *activeKeys;
@property(nonatomic, strong) UITapGestureRecognizer *tapGesture;

@property(nonatomic, strong) NSString *clickedAddress;

- (IBAction)shareClicked:(id)sender;
- (IBAction)moreActionsClicked:(id)sender;
- (IBAction)labelAddressClicked:(id)sender;
- (IBAction)archiveAddressClicked:(id)sender;
- (IBAction)copyAddressClicked:(id)sender;
- (IBAction)labelSaveClicked:(id)sender;

- (void)reload;

- (void)hideKeyboard;
- (void)showKeyboard;

@end

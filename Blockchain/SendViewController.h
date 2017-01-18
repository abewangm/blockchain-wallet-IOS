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
#import "BCAddressSelectionView.h"
#import "BCConfirmPaymentView.h"
#import <AVFoundation/AVFoundation.h>
#import "BCLine.h"

@class Wallet;

@interface SendViewController : UIViewController <AVCaptureMetadataOutputObjectsDelegate, AddressSelectionDelegate> {
    IBOutlet UIView *containerView;
    
    IBOutlet UILabel *fromLabel;
    IBOutlet UITextField *selectAddressTextField;
    IBOutlet UIButton *selectFromButton;
    IBOutlet UIButton *fundsAvailableButton;
    
    IBOutlet UILabel *toLabel;
    IBOutlet UITextField *toField;
    IBOutlet UIButton *addressBookButton;

    IBOutlet UILabel *btcLabel;
    IBOutlet UITextField *btcAmountField;
    IBOutlet UILabel *fiatLabel;
    IBOutlet UITextField *fiatAmountField;
    
    IBOutlet UIButton *continuePaymentButton;
    IBOutlet UIButton *continuePaymentAccessoryButton;
    
    IBOutlet UIView *amountKeyboardAccessoryView;
    
    IBOutlet UIView *labelAddressView;
    IBOutlet UILabel *labelAddressLabel;
    IBOutlet UITextField *labelAddressTextField;
    
    IBOutlet UIView *sendProgressModal;
    IBOutlet UILabel *sendProgressModalText;
    IBOutlet UIActivityIndicatorView *sendProgressActivityIndicator;
    IBOutlet UIButton *sendProgressCancelButton;

    IBOutlet UILabel *feeLabel;
    IBOutlet UITextField *feeField;
    
    IBOutlet BCLine *lineBelowFromField;
    IBOutlet BCLine *lineBelowToField;
    IBOutlet BCLine *lineBelowAmountFields;
    IBOutlet BCLine *lineBelowFeeField;
    
    IBOutlet UIView *bottomContainerView;
    
    IBOutlet UIButton *feeInformationButton;
    BOOL displayingLocalSymbol;
}

@property (strong, nonatomic) IBOutlet BCConfirmPaymentView *confirmPaymentView;

typedef enum {
    DestinationAddressSourceNone,
    DestinationAddressSourceQR,
    DestinationAddressSourcePaste,
    DestinationAddressSourceURI,
    DestinationAddressSourceDropDown,
} DestinationAddressSource;

@property (nonatomic, readonly) DestinationAddressSource addressSource;

@property(nonatomic, strong) NSString *addressFromURLHandler;

@property(nonatomic, strong) NSString *fromAddress;
@property(nonatomic, strong) NSString *toAddress;
@property int fromAccount;
@property int toAccount;
@property BOOL sendFromAddress;
@property BOOL sendToAddress;
@property BOOL surgeIsOccurring;

@property (nonatomic) BOOL isSending;

@property(nonatomic, strong) UITapGestureRecognizer *tapGesture;

- (BOOL)transferAllMode;

- (IBAction)selectFromAddressClicked:(id)sender;
- (IBAction)QRCodebuttonClicked:(id)sender;
- (IBAction)addressBookClicked:(id)sender;
- (IBAction)closeKeyboardClicked:(id)sender;

- (void)didSelectFromAddress:(NSString *)address;
- (void)didSelectToAddress:(NSString *)address;
- (void)didSelectFromAccount:(int)account;
- (void)didSelectToAccount:(int)account;

- (void)updateSendBalance:(NSNumber *)balance;

- (IBAction)sendPaymentClicked:(id)sender;
- (IBAction)labelAddressClicked:(id)sender;
- (IBAction)useAllClicked:(id)sender;

- (void)setAmountFromUrlHandler:(NSString*)amountString withToAddress:(NSString*)string;

- (NSString *)labelForLegacyAddress:(NSString *)address;

- (void)sendFromWatchOnlyAddress;
- (void)didCheckForOverSpending:(NSNumber *)amount fee:(NSNumber *)fee;
- (void)didGetMaxFee:(NSNumber *)fee amount:(NSNumber *)amount dust:(NSNumber *)dust willConfirm:(BOOL)willConfirm;
- (void)didGetFeeBounds:(NSArray *)bounds confirmationEstimation:(NSNumber *)confirmationEstimation maxAmounts:(NSArray *)maxAmounts maxFees:(NSArray *)maxFees;
- (void)didGetFee:(NSNumber *)fee dust:(NSNumber *)dust txSize:(NSNumber *)txSize;
- (void)didChangeForcedFee:(NSNumber *)fee dust:(NSNumber *)dust;

- (void)setupTransferAll;
- (void)getInfoForTransferAllFundsToDefaultAccount;
- (void)transferFundsToDefaultAccountFromAddress:(NSString *)address;
- (void)updateTransferAllAmount:(NSNumber *)amount fee:(NSNumber *)fee addressesUsed:(NSArray *)addressesUsed;
- (void)showSummaryForTransferAll;
- (void)sendDuringTransferAll:(NSString *)secondPassword;
- (void)didErrorDuringTransferAll:(NSString *)error secondPassword:(NSString *)secondPassword;

- (void)reload;
- (void)reloadAfterMultiAddressResponse;
- (void)reloadSymbols;
- (void)resetFromAddress;

- (void)hideKeyboard;
- (void)hideKeyboardForced;

- (void)enablePaymentButtons;

// Called on manual logout
- (void)clearToAddressAndAmountFields;

@end

//
//  TransferAllFundsBuilder.m
//  Blockchain
//
//  Created by Kevin Wu on 10/14/16.
//  Copyright © 2016 Blockchain Luxembourg S.A. All rights reserved.
//

#import "TransferAllFundsBuilder.h"
#import "RootService.h"
@interface TransferAllFundsBuilder()
@property (nonatomic) NSString *temporarySecondPassword;
@end
@implementation TransferAllFundsBuilder

- (id)initOnSendScreen:(BOOL)onSendScreen
{
    if (self = [super init]) {
        _onSendScreen = onSendScreen;
        [self getTransferAllInfo];
    }
    return self;
}

- (void)getTransferAllInfo
{
    [app.wallet getInfoForTransferAllFundsToDefaultAccount];
}

- (void)setupFirstTransferWithAddressesUsed:(NSArray *)addressesUsed
{
    self.transferAllAddressesToTransfer = [[NSMutableArray alloc] initWithArray:addressesUsed];
    self.transferAllAddressesTransferred = [[NSMutableArray alloc] init];
    self.transferAllAddressesInitialCount = (int)[self.transferAllAddressesToTransfer count];
    self.transferAllAddressesUnspendable = 0;
    
    [self setupFirstTransfer];
}

- (void)setupFirstTransfer
{
    if (self.onSendScreen) {
        [app.wallet setupFirstTransferForAllFundsToDefaultAccount:[self.transferAllAddressesToTransfer firstObject] secondPassword:nil];
    } else {
        [app.wallet setupFirstTransferForAllFundsToDefaultAccountInBackup:[self.transferAllAddressesToTransfer firstObject] secondPassword:nil];
    }
}

- (void)transferAllFundsToDefaultAccountWithSecondPassword:(NSString *)_secondPassword
{
    if (self.userCancelledNext) {
        [self finishedTransferFunds];
        return;
    }
    
    transactionProgressListeners *listener = [[transactionProgressListeners alloc] init];
    
    listener.on_start = ^() {
    };
    
    listener.on_begin_signing = ^() {
    };
    
    listener.on_sign_progress = ^(int input) {
    };
    
    listener.on_finish_signing = ^() {
    };
    
    listener.on_success = ^(NSString*secondPassword) {
        
        DLog(@"SendViewController: on_success_transfer_all for address %@", [self.transferAllAddressesToTransfer firstObject]);
        
        self.temporarySecondPassword = secondPassword;
        
        [app.wallet incrementReceiveIndexOfDefaultAccount];
        // Fields are automatically reset by reload, called by MyWallet.wallet.getHistory() after a utx websocket message is received. However, we cannot rely on the websocket 100% of the time.
        [app.wallet performSelector:@selector(getHistoryIfNoTransactionMessage) withObject:nil afterDelay:DELAY_GET_HISTORY_BACKUP];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(continueTransferringFunds) name:NOTIFICATION_KEY_MULTIADDRESS_RESPONSE_RELOAD object:nil];
        
        if (self.on_success) self.on_success(secondPassword);
    };
    
    listener.on_error = ^(NSString* error, NSString* secondPassword) {
        DLog(@"Send error: %@", error);
        
        if ([error containsString:ERROR_ALL_OUTPUTS_ARE_VERY_SMALL]) {
            self.transferAllAddressesUnspendable++;
            self.temporarySecondPassword = secondPassword;
            [self continueTransferringFunds];
            DLog(@"Output too small; continuing transfer all");
            return;
        }
                
        if ([error isEqualToString:ERROR_UNDEFINED]) {
            [app standardNotify:BC_STRING_SEND_ERROR_NO_INTERNET_CONNECTION];
        } else if ([error isEqualToString:ERROR_FAILED_NETWORK_REQUEST]) {
            [app standardNotify:BC_STRING_REQUEST_FAILED_PLEASE_CHECK_INTERNET_CONNECTION];
        } else if (error && error.length != 0)  {
            [app standardNotify:error];
        }
        
        if (self.on_error) self.on_error(error, secondPassword);
        
        [app.wallet getHistory];
    };
    
    if (self.on_before_send) self.on_before_send();
    
    app.wallet.didReceiveMessageForLastTransaction = NO;
    
    if (self.onSendScreen) {
        [app.wallet sendPaymentWithListener:listener secondPassword:_secondPassword];
    } else {
        [app.wallet transferFundsBackupWithListener:listener secondPassword:_secondPassword];
    }
}

- (void)continueTransferringFunds
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:NOTIFICATION_KEY_MULTIADDRESS_RESPONSE_RELOAD object:nil];
    
    if ([self.transferAllAddressesToTransfer count] > 0) {
        [self.transferAllAddressesTransferred addObject:self.transferAllAddressesToTransfer[0]];
    }
    
    if ([self.transferAllAddressesToTransfer count] > 1 && !self.userCancelledNext) {
        [self.transferAllAddressesToTransfer removeObjectAtIndex:0];
        if (self.on_prepare_next_transfer) self.on_prepare_next_transfer(self.transferAllAddressesToTransfer);
        [app.wallet setupFollowingTransferForAllFundsToDefaultAccount:self.transferAllAddressesToTransfer[0] secondPassword:self.temporarySecondPassword];
    } else {
        [self.transferAllAddressesToTransfer removeAllObjects];
        [self finishedTransferFunds];
    }
}

- (void)finishedTransferFunds
{
    NSString *summary;
    if (self.transferAllAddressesUnspendable > 0) {
        
        NSString *addressOrAddressesTransferred = self.transferAllAddressesInitialCount - self.transferAllAddressesUnspendable == 1 ? [BC_STRING_ADDRESS lowercaseString] : [BC_STRING_ADDRESSES lowercaseString];
        NSString *addressOrAddressesSkipped = self.transferAllAddressesUnspendable == 1 ? [BC_STRING_ADDRESS lowercaseString] : [BC_STRING_ADDRESSES lowercaseString];
        
        summary = [NSString stringWithFormat:BC_STRING_PAYMENT_TRANSFERRED_FROM_ARGUMENT_ARGUMENT_OUTPUTS_ARGUMENT_ARGUMENT_TOO_SMALL, self.transferAllAddressesInitialCount - self.transferAllAddressesUnspendable, addressOrAddressesTransferred, self.transferAllAddressesUnspendable, addressOrAddressesSkipped];
    } else {
        
        NSString *addressOrAddressesTransferred = [self.transferAllAddressesTransferred count] == 1 ? [BC_STRING_ADDRESS lowercaseString] : [BC_STRING_ADDRESSES lowercaseString];
        
        summary = [NSString stringWithFormat:BC_STRING_PAYMENT_TRANSFERRED_FROM_ARGUMENT_ARGUMENT, [self.transferAllAddressesTransferred count], addressOrAddressesTransferred];
    }
    
    [self.delegate didFinishTransferFunds:summary];
}

@end

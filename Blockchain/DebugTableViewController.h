//
//  DebugTableViewController.h
//  Blockchain
//
//  Created by Kevin Wu on 12/29/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DebugTableViewController : UITableViewController
@property (nonatomic) int presenter;
typedef NS_ENUM(NSInteger, DebugTableViewRow) {
    RowWalletJSON,
    RowServerURL,
    RowWebsocketURL,
    RowMerchantURL,
    RowAPIURL,
    RowBuyURL,
    RowSurgeToggle,
    RowDontShowAgain,
    RowAppStoreReviewPromptTimer,
    RowCertificatePinning,
    RowTestnet,
    RowSecurityReminderTimer,
    RowZeroTickerValue
};
@end

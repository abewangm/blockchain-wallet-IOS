//
//  BackupViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 19-05-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BackupViewController: UIViewController {
    
    @IBOutlet weak var summaryLabel: UILabel?
    @IBOutlet weak var backupWalletButton: UIButton?
    @IBOutlet weak var explanation: UILabel?
    @IBOutlet weak var backupIconImageView: UIImageView?
    @IBOutlet weak var backupWalletAgainButton: UIButton?
    @IBOutlet weak var lostRecoveryPhraseLabel: UILabel!
    
    var wallet : Wallet?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        backupWalletButton?.setTitle(NSLocalizedString("BACKUP FUNDS", comment: ""), forState: .Normal)
        backupWalletButton?.titleLabel?.adjustsFontSizeToFitWidth = true
        backupWalletButton?.contentHorizontalAlignment = .Center
        backupWalletButton?.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)
        backupWalletButton?.clipsToBounds = true
        backupWalletButton?.layer.cornerRadius = Constants.Measurements.BackupButtonCornerRadius
        
        if wallet!.isRecoveryPhraseVerified() {
            summaryLabel!.text = NSLocalizedString("You backed up your funds successfully", comment: "");
            explanation!.text = NSLocalizedString("Now you can restore your funds using the 12 word recovery phrase in case you lose your wallet's password", comment: "")
            backupIconImageView!.image = UIImage(named: "thumbs")
            backupWalletButton?.setTitle(NSLocalizedString("VERIFY BACKUP", comment: ""), forState: .Normal)
            backupWalletAgainButton?.hidden = false
            lostRecoveryPhraseLabel?.hidden = false
            lostRecoveryPhraseLabel?.adjustsFontSizeToFitWidth = true;
            
            // Override any font changes
            backupWalletAgainButton?.titleLabel?.font = UIFont.boldSystemFontOfSize(14);
            lostRecoveryPhraseLabel?.font = UIFont.boldSystemFontOfSize(14);
        }
        
        explanation?.sizeToFit();
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (backupWalletAgainButton?.hidden == false) {
            backupWalletButton?.setTitle(NSLocalizedString("VERIFY BACKUP", comment: ""), forState: .Normal)
        } else {
            backupWalletButton?.setTitle(NSLocalizedString("BACKUP FUNDS", comment: ""), forState: .Normal)
        }
    }
    
    @IBAction func backupWalletButtonTapped(sender: UIButton) {
        if (backupWalletButton!.titleLabel!.text == NSLocalizedString("VERIFY BACKUP", comment: "")) {
            performSegueWithIdentifier("verifyBackup", sender: nil)
        } else {
            performSegueWithIdentifier("backupWords", sender: nil)
        }
    }
    
    @IBAction func backupWalletAgainButtonTapped(sender: UIButton) {
        performSegueWithIdentifier("backupWords", sender: nil)
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "backupWords" {
            let vc = segue.destinationViewController as! BackupWordsViewController
            vc.wallet = wallet
        }
        else if segue.identifier == "verifyBackup" {
            let vc = segue.destinationViewController as! BackupVerifyViewController
            vc.wallet = wallet
            vc.isVerifying = true
        }
    }
}
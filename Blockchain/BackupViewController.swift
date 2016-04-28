//
//  BackupViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 19-05-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BackupViewController: UIViewController {
    
    @IBOutlet weak var summaryLabel: UILabel!
    @IBOutlet weak var backupWalletButton: UIButton!
    @IBOutlet weak var explanation: UILabel!
    @IBOutlet weak var backupIconImageView: UIImageView!
    @IBOutlet weak var backupWalletAgainButton: UIButton!
    @IBOutlet weak var lostRecoveryPhraseLabel: UILabel!
    
    var wallet : Wallet?
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        backupWalletButton.setTitle(NSLocalizedString("BACKUP FUNDS", comment: ""), forState: .Normal)
        backupWalletButton.titleLabel?.adjustsFontSizeToFitWidth = true
        backupWalletButton.contentHorizontalAlignment = .Center
        backupWalletButton.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0)
        backupWalletButton.clipsToBounds = true
        backupWalletButton.layer.cornerRadius = Constants.Measurements.BackupButtonCornerRadius
        
        if wallet!.isRecoveryPhraseVerified() {
            summaryLabel.text = NSLocalizedString("You backed up your funds successfully.", comment: "");
            explanation.text = NSLocalizedString("Should you lose your password, you can restore your current funds and funds you will receive in this wallet in the future (except imported addresses) using the 12 word recovery phrase. It is very important to keep your Recovery Phrase offline somewhere very safe and secure. Anyone with access to your Recovery Phrase has access to your bitcoins.", comment: "")
            backupIconImageView.image = UIImage(named: "thumbs")
            backupWalletButton.setTitle(NSLocalizedString("VERIFY BACKUP", comment: ""), forState: .Normal)
            backupWalletAgainButton.hidden = false
            backupWalletAgainButton.titleLabel?.textAlignment = .Center;
            backupWalletAgainButton.titleLabel?.adjustsFontSizeToFitWidth = true;
            lostRecoveryPhraseLabel.hidden = false
            lostRecoveryPhraseLabel.adjustsFontSizeToFitWidth = true;
            lostRecoveryPhraseLabel.textAlignment = .Center;
            
            // Override any font changes
            backupWalletAgainButton.titleLabel?.font = UIFont.boldSystemFontOfSize(14);
            lostRecoveryPhraseLabel.font = UIFont.boldSystemFontOfSize(14);
        }
        
        explanation.sizeToFit();
        explanation.center = CGPointMake(view.frame.width/2, explanation.center.y)
        changeYPosition(explanation.frame.origin.y + explanation.frame.size.height + 20, view: backupWalletButton)
        changeYPosition(backupWalletButton.frame.origin.y + backupWalletButton.frame.size.height + 20, view: lostRecoveryPhraseLabel)
        changeYPosition(lostRecoveryPhraseLabel.frame.origin.y + 10, view: backupWalletAgainButton)
        
        if (backupWalletAgainButton.frame.origin.y + backupWalletAgainButton.frame.size.height > view.frame.size.height) {
            changeYPosition(view.frame.size.height - backupWalletAgainButton.frame.size.height, view: backupWalletAgainButton)
            changeYPosition(backupWalletAgainButton.frame.origin.y - 10, view: lostRecoveryPhraseLabel)
            changeYPosition(lostRecoveryPhraseLabel.frame.origin.y - backupWalletAgainButton.frame.size.height - 20, view: backupWalletButton)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (backupWalletAgainButton?.hidden == false) {
            backupWalletButton?.setTitle(NSLocalizedString("VERIFY BACKUP", comment: ""), forState: .Normal)
        } else {
            backupWalletButton?.setTitle(NSLocalizedString("BACKUP FUNDS", comment: ""), forState: .Normal)
        }
    }
    
    func changeYPosition(newY: CGFloat, view: UIView) {
        view.frame = CGRectMake(view.frame.origin.x, newY, view.frame.size.width, view.frame.size.height);
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
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
    
    var wallet : Wallet?

    override func viewDidLoad() {
        super.viewDidLoad()
    
        backupWalletButton?.clipsToBounds = true
        backupWalletButton?.layer.cornerRadius = Constants.Measurements.BackupButtonCornerRadius
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if wallet!.isRecoveryPhraseVerified() {
            summaryLabel!.text = NSLocalizedString("You backed up your wallet.", comment: "");
            explanation!.text = NSLocalizedString("You only need to backup your wallet once.", comment: "")
            backupIconImageView!.image = UIImage(named: "icon_backup_complete")
            backupWalletButton?.titleLabel?.text = NSLocalizedString("VERIFY BACKUP", comment: "");
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! BackupWordsViewController
        vc.wallet = wallet
    }
    
    @IBAction func unwindSecondPasswordCancel(segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindVerifyWords(segue: UIStoryboardSegue) {
    }
}
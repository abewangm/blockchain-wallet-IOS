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
    @IBOutlet weak var backupIconImageView: UIImageView!
    
    var wallet : Wallet?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let closeButton = UIBarButtonItem(title: "Close", style: .Plain, target: self, action: "close:")
        closeButton.tintColor = UIColor.whiteColor()
        
        self.navigationItem.setRightBarButtonItem(closeButton, animated: false)
    
        backupWalletButton?.clipsToBounds = true
        backupWalletButton?.layer.cornerRadius = Constants.Measurements.BackupButtonCornerRadius
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if wallet!.isRecoveryPhraseVerified() {
            summaryLabel!.text = "You backed up your wallet."
            explanation!.text = "You only need to backup your wallet once."
            backupIconImageView!.image = UIImage(named: "icon_backup_complete")
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
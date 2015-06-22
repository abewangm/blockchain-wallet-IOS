//
//  BackupWordsViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 19-05-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BackupWordsViewController: UIViewController, SecondPasswordDelegate {
    
    @IBOutlet weak var wordsLabel: UILabel?
    @IBOutlet weak var verifyButton: UIButton?

    var wallet : Wallet?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        wallet!.addObserver(self, forKeyPath: "recoveryPhrase", options: .New, context: nil)
        
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        

        if wallet!.needsSecondPassword(){
            self.performSegueWithIdentifier("secondPasswordForBackup", sender: self)
        } else {
            wallet!.getRecoveryPhrase(nil)
        }
        
        if wallet!.isRecoveryPhraseVerified() {
            verifyButton?.hidden = true
        }

        
        wordsLabel!.text = ""

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
    }
    

    // MARK: - Navigation

    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "secondPasswordForBackup" {
            let vc = segue.destinationViewController as! SecondPasswordViewController
            vc.delegate = self
            vc.wallet = wallet
        } else if segue.identifier == "backupVerify" {
            let vc = segue.destinationViewController as! BackupVerifyViewController
            vc.wallet = wallet
        }
    }
    
    func didGetSecondPassword(password: String) {
        wallet!.getRecoveryPhrase(password)
    }
    
    @IBAction func unwindSecondPasswordSuccess(segue: UIStoryboardSegue) {
    }
    
    override func observeValueForKeyPath(keyPath: String, ofObject object: AnyObject, change: [NSObject: AnyObject], context: UnsafeMutablePointer<Void>) {
        
        if let theWallet = wallet {
            wordsLabel!.text = theWallet.recoveryPhrase.stringByReplacingOccurrencesOfString(" ", withString: "\n")
        }
    }
    
    deinit {
        wallet!.removeObserver(self, forKeyPath: "recoveryPhrase", context: nil)
    }
}
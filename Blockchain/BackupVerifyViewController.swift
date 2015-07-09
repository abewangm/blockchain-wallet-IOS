//
//  BackupVerifyViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 19-05-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BackupVerifyViewController: UIViewController, UITextFieldDelegate, SecondPasswordDelegate {
    
    var wallet : Wallet?
    var isVerifying = false
    var verifyButton : UIButton?
    
    @IBOutlet weak var word1: UITextField?
    @IBOutlet weak var word2: UITextField?
    @IBOutlet weak var word3: UITextField?
    
    @IBOutlet weak var wrongWord: UILabel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
            
        word1?.addTarget(self, action: "textFieldDidChange", forControlEvents: .EditingChanged)
        word2?.addTarget(self, action: "textFieldDidChange", forControlEvents: .EditingChanged)
        word3?.addTarget(self, action: "textFieldDidChange", forControlEvents: .EditingChanged)
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        
        
        if (!wallet!.needsSecondPassword() && isVerifying) {
            
            // if you don't need a second password but you are verifying, get recovery phrase
            
            wallet!.getRecoveryPhrase(nil)
        } else if wallet!.needsSecondPassword() && !isVerifying {
            
            // do not segue since words vc already asks for second password and gets recovery phrase
            
        } else if wallet!.needsSecondPassword() {
            
            // if you need a second password, the second password delegate takes care of getting the recovery phrase
            
            self.performSegueWithIdentifier("verifyBackupWithSecondPassword", sender: self)
        }
    }
    
    override func viewDidAppear(animated: Bool) {
        verifyButton = UIButton(frame: CGRectMake(0, 0, view.frame.size.width, 46))
        verifyButton?.setTitle(NSLocalizedString("VERIFY BACKUP", comment:""), forState: .Normal)
        verifyButton?.setTitle(NSLocalizedString("VERIFY BACKUP", comment:""), forState: .Disabled)
        verifyButton?.backgroundColor = Constants.Colors.SecondaryGray
        verifyButton?.setTitleColor(UIColor.lightGrayColor(), forState: .Disabled)
        verifyButton?.titleLabel!.font = UIFont.boldSystemFontOfSize(15)
        verifyButton?.enabled = true
        verifyButton?.addTarget(self, action: "done", forControlEvents: .TouchUpInside)
        verifyButton?.enabled = false
        word1?.inputAccessoryView = verifyButton
        word2?.inputAccessoryView = verifyButton
        word3?.inputAccessoryView = verifyButton
        word1?.becomeFirstResponder()
    }
    
    func done() {
        checkWords()
    }
    
    func checkWords() {
        var valid = true
        
        let words = wallet!.recoveryPhrase.componentsSeparatedByString(" ")
        
        if word1!.text.isEmpty || word2!.text.isEmpty || word3!.text.isEmpty {
            valid = false
        } else { // Don't mark words as invalid until the user has entered all three
            if word1!.text != words[0] {
                pleaseTryAgain()
                return
            }
            if word2!.text != words[2] {
                pleaseTryAgain()
                return
            }
            if word3!.text != words[5] {
                pleaseTryAgain()
                return
            }
        }
        
        if valid {
            word1?.resignFirstResponder()
            word2?.resignFirstResponder()
            word3?.resignFirstResponder()
            wallet!.markRecoveryPhraseVerified()
            NSNotificationCenter.defaultCenter().postNotificationName("AppDelegateReload", object: nil)
            self.performSegueWithIdentifier("unwindVerifyWords", sender: self)
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        wrongWord?.hidden = true
        return true
    }
    
    func pleaseTryAgain() {
        var alertView = UIAlertView()
        alertView.title = NSLocalizedString("Error", comment:"")
        alertView.message = NSLocalizedString("Please try again", comment:"")
        alertView.addButtonWithTitle(NSLocalizedString("OK", comment:""))
        alertView.show()
    }
    
    func textFieldDidChange() {
        if !word1!.text.isEmpty && !word2!.text.isEmpty && !word3!.text.isEmpty {
            verifyButton?.backgroundColor = Constants.Colors.BlockchainBlue
            verifyButton?.enabled = true
            verifyButton?.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        } else if word1!.text.isEmpty || word2!.text.isEmpty || word3!.text.isEmpty {
            verifyButton?.backgroundColor = Constants.Colors.SecondaryGray
            verifyButton?.enabled = false
            verifyButton?.setTitleColor(UIColor.lightGrayColor(), forState: .Disabled)
        }
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        if (word1!.isFirstResponder()) {
            textField.resignFirstResponder()
            word2?.becomeFirstResponder()
        } else if (word2!.isFirstResponder()) {
            textField.resignFirstResponder()
            word3?.becomeFirstResponder()
        } else if (word3!.isFirstResponder()) {
            checkWords()
        }
        return true
    }
    
    @IBAction func unwindFromSecondPasswordToVerify(segue: UIStoryboardSegue) {
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        if segue.identifier == "verifyBackupWithSecondPassword" {
            let vc = segue.destinationViewController as! SecondPasswordViewController
            vc.delegate = self
            vc.wallet = wallet
        }
    }
    
    func didGetSecondPassword(password: String) {
            wallet!.getRecoveryPhrase(password)
        }
}

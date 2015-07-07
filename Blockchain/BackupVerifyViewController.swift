//
//  BackupVerifyViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 19-05-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BackupVerifyViewController: UIViewController, UITextFieldDelegate {
    
    var wallet : Wallet?
    
    @IBOutlet weak var word1: UITextField?
    @IBOutlet weak var word2: UITextField?
    @IBOutlet weak var word3: UITextField?
    
    @IBOutlet weak var wrongWord1: UILabel?
    @IBOutlet weak var wrongWord2: UILabel?
    @IBOutlet weak var wrongWord3: UILabel?
    
    @IBOutlet weak var verifyButton: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationController?.navigationBar.tintColor = UIColor.whiteColor()
        verifyButton.clipsToBounds = true
        verifyButton.layer.cornerRadius = Constants.Measurements.BackupButtonCornerRadius
    }
    
    @IBAction func done(sender: UIButton) {
        checkWords()
    }
    
    func checkWords() {
        var valid = true
        
        let words = wallet!.recoveryPhrase.componentsSeparatedByString(" ")
        
        if word1!.text.isEmpty || word2!.text.isEmpty || word3!.text.isEmpty {
            valid = false
        } else { // Don't mark words as invalid until the user has entered all three
            if word1!.text != words[0] {
                wrongWord1?.hidden = false
                valid = false
            }
            if word2!.text != words[2] {
                wrongWord2?.hidden = false
                valid = false
            }
            if word3!.text != words[5] {
                wrongWord3?.hidden = false
                valid = false
            }
        }
        
        if valid {
            wallet!.markRecoveryPhraseVerified()
            NSNotificationCenter.defaultCenter().postNotificationName("AppDelegateReload", object: nil)
            self.performSegueWithIdentifier("unwindVerifyWords", sender: self)
        }
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        wrongWord1?.hidden = true
        wrongWord2?.hidden = true
        wrongWord3?.hidden = true
        return true
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        checkWords()
        return true
    }

}

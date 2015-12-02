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
    var randomizedIndexes : [Int] = []
    var indexDictionary = [0:NSLocalizedString("first word", comment:""),
        1:NSLocalizedString("second word", comment:""),
        2:NSLocalizedString("third word", comment:""),
        3:NSLocalizedString("fourth word", comment:""),
        4:NSLocalizedString("fifth word", comment:""),
        5:NSLocalizedString("sixth word", comment:""),
        6:NSLocalizedString("seventh word", comment:""),
        7:NSLocalizedString("eighth word", comment:""),
        8:NSLocalizedString("ninth word", comment:""),
        9:NSLocalizedString("tenth word", comment:""),
        10:NSLocalizedString("eleventh word", comment:""),
        11:NSLocalizedString("twelfth word", comment:"")]
    
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
        
        randomizeCheckIndexes()
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
        if (randomizedIndexes.count >= 3) {
            word1?.placeholder = indexDictionary[randomizedIndexes[0]]
            word2?.placeholder = indexDictionary[randomizedIndexes[1]]
            word3?.placeholder = indexDictionary[randomizedIndexes[2]]
        }
        word1?.becomeFirstResponder()
    }
    
    func randomizeCheckIndexes() {
        var wordIndexes: [Int] = [];
        for (var i = 0; i < Constants.Defaults.NumberOfRecoveryPhraseWords; i++) {
            wordIndexes.append(i)
        }
        randomizedIndexes = wordIndexes.shuffle()
    }
    
    func done() {
        checkWords()
    }
    
    func checkWords() {
        var valid = true
        
        let words = wallet!.recoveryPhrase.componentsSeparatedByString(" ")
        
        var randomWord1 : String
        var randomWord2 : String
        var randomWord3 : String
        
        if (randomizedIndexes.count >= 3) {
            randomWord1 = words[randomizedIndexes[0]]
            randomWord2 = words[randomizedIndexes[1]]
            randomWord3 = words[randomizedIndexes[2]]
            
            if word1!.text!.isEmpty || word2!.text!.isEmpty || word3!.text!.isEmpty {
                valid = false
            } else { // Don't mark words as invalid until the user has entered all three
                if word1!.text != randomWord1 {
                    word1?.textColor = UIColor.redColor()
                    valid = false
                }
                if word2!.text != randomWord2 {
                    word2?.textColor = UIColor.redColor()
                    valid = false
                }
                if word3!.text != randomWord3 {
                    word3?.textColor = UIColor.redColor()
                    valid = false
                }
                
                if (!valid) {
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
    }
    
    func textField(textField: UITextField, shouldChangeCharactersInRange range: NSRange, replacementString string: String) -> Bool {
        textField.textColor = UIColor.blackColor()
        wrongWord?.hidden = true
        return true
    }
    
    func pleaseTryAgain() {
        let alertView = UIAlertView()
        alertView.title = NSLocalizedString("Error", comment:"")
        alertView.message = NSLocalizedString("Please try again", comment:"")
        alertView.addButtonWithTitle(NSLocalizedString("OK", comment:""))
        alertView.show()
    }
    
    func textFieldDidChange() {
        if !word1!.text!.isEmpty && !word2!.text!.isEmpty && !word3!.text!.isEmpty {
            verifyButton?.backgroundColor = Constants.Colors.BlockchainBlue
            verifyButton?.enabled = true
            verifyButton?.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        } else if word1!.text!.isEmpty || word2!.text!.isEmpty || word3!.text!.isEmpty {
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

extension CollectionType where Index == Int {
    /// Return a copy of `self` with its elements shuffled
    func shuffle() -> [Generator.Element] {
        var list = Array(self)
        list.shuffleInPlace()
        return list
    }
}

extension MutableCollectionType where Index == Int {
    /// Shuffle the elements of `self` in-place.
    mutating func shuffleInPlace() {
        // empty and single-element collections don't shuffle
        if count < 2 { return }
        
        for i in 0..<count - 1 {
            let j = Int(arc4random_uniform(UInt32(count - i))) + i
            guard i != j else { continue }
            swap(&self[i], &self[j])
        }
    }
}
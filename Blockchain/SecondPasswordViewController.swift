//
//  SecondPasswordViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 18-06-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

let BC_ALERTVIEW_SECOND_PASSWORD_ERROR_TAG = 2

protocol SecondPasswordDelegate {
    func didGetSecondPassword(_: String)
    var isVerifying : Bool {get set}
}

class SecondPasswordViewController: UIViewController, UITextFieldDelegate, UIAlertViewDelegate {

    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var password: UITextField?
    
    var wallet : Wallet?
    
    var delegate : SecondPasswordDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationBar!.backgroundColor = UIColor.blueColor()
    }
    
    override func viewDidAppear(animated: Bool) {
        let continueButton = UIButton(frame: CGRectMake(0, 0, view.frame.size.width, 46))
        continueButton.backgroundColor = Constants.Colors.BlockchainBlue;
        continueButton.setTitle(NSLocalizedString("Continue", comment:""), forState: .Normal)
        continueButton.setTitleColor(UIColor.whiteColor(), forState: .Normal)
        continueButton.titleLabel!.font = UIFont.systemFontOfSize(17)
        continueButton.enabled = true
        continueButton.addTarget(self, action: "done", forControlEvents: .TouchUpInside)
        password?.inputAccessoryView = continueButton
        password?.becomeFirstResponder()
    }

    func done() {
        checkSecondPassword()
    }
    
    @IBAction func close(sender: UIBarButtonItem) {
        password?.resignFirstResponder()
        self.performSegueWithIdentifier("unwindSecondPasswordCancel", sender: self)
    }
    
    func checkSecondPassword() {
        let secondPassword = password!.text
        if secondPassword!.isEmpty {
            alertUserWithErrorMessage((NSLocalizedString("No Password Entered", comment: "")))
        }
        else if wallet!.validateSecondPassword(secondPassword) {
            password?.resignFirstResponder()
            delegate?.didGetSecondPassword(secondPassword!)
            if (delegate!.isVerifying) {
                // if we are verifying backup, unwind to verify words view controller
                self.performSegueWithIdentifier("unwindSecondPasswordToVerify", sender: self)
            } else {
                self.performSegueWithIdentifier("unwindSecondPasswordSuccess", sender: self)
            }
        } else {
            alertUserWithErrorMessage((NSLocalizedString("Second Password Incorrect", comment: "")))
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == BC_ALERTVIEW_SECOND_PASSWORD_ERROR_TAG {
            password?.text = ""
        }
    }
    
    func alertUserWithErrorMessage(message : String) {
        let alertView = UIAlertView()
        alertView.title = NSLocalizedString("Error", comment:"")
        alertView.message = message;
        alertView.addButtonWithTitle(NSLocalizedString("OK", comment:""))
        alertView.tag = BC_ALERTVIEW_SECOND_PASSWORD_ERROR_TAG;
        alertView.delegate = self
        alertView.show()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        checkSecondPassword()
        return true
    }
    
}
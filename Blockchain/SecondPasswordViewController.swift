//
//  SecondPasswordViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 18-06-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

protocol SecondPasswordDelegate {
    func didGetSecondPassword(String)
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

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    @IBAction func done(sender: UIButton) {
        checkSecondPassword()
    }
    
    @IBAction func close(sender: UIBarButtonItem) {
        self.performSegueWithIdentifier("unwindSecondPasswordCancel", sender: self)
    }
    
    func checkSecondPassword() {
        let secondPassword = password!.text
        if secondPassword.isEmpty {
            alertUserWithErrorMessage((NSLocalizedString("No Password Entered", comment: "")))
        }
        else if wallet!.validateSecondPassword(secondPassword) {
            delegate?.didGetSecondPassword(secondPassword)
            self.performSegueWithIdentifier("unwindSecondPasswordSuccess", sender: self)
        } else {
            alertUserWithErrorMessage((NSLocalizedString("Second Password Incorrect", comment: "")))
        }
    }
    
    func alertView(alertView: UIAlertView, clickedButtonAtIndex buttonIndex: Int) {
        if alertView.tag == 2 {
            password?.text = ""
        }
    }
    
    func alertUserWithErrorMessage(message : String) {
        var alertView = UIAlertView()
        alertView.title = NSLocalizedString("Error", comment:"")
        alertView.message = message;
        alertView.addButtonWithTitle(NSLocalizedString("OK", comment:""))
        alertView.tag = 2;
        alertView.delegate = self
        alertView.show()
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        checkSecondPassword()
        return true
    }
    
}
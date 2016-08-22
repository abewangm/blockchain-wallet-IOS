//
//  SecondPasswordViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 18-06-15.
//  Copyright (c) 2015 Blockchain Luxembourg S.A. All rights reserved.
//

import UIKit

protocol SecondPasswordDelegate {
    func didGetSecondPassword(_: String)
    func returnToRootViewController(completionHandler: () -> Void ) -> Void
    var isVerifying : Bool {get set}
}

class SecondPasswordViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var password: UITextField?
    var topBar: UIView?
    var closeButton: UIButton?
    
    var wallet : Wallet?
    
    var delegate : SecondPasswordDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topBar = UIView(frame:CGRectMake(0, 0, self.view.frame.size.width, Constants.Measurements.DefaultHeaderHeight));
        topBar!.backgroundColor = Constants.Colors.BlockchainBlue
        self.view.addSubview(topBar!);
        
        let headerLabel = UILabel(frame:CGRectMake(80, 20.5, self.view.frame.size.width - 160, 40));
        headerLabel.font = UIFont.systemFontOfSize(13.0)
        headerLabel.textColor = UIColor.whiteColor()
        headerLabel.textAlignment = .Center;
        headerLabel.adjustsFontSizeToFitWidth = true;
        headerLabel.text = NSLocalizedString("Second Password Required", comment: "");
        topBar!.addSubview(headerLabel);
        
        closeButton = UIButton(type: UIButtonType.Custom)
        closeButton!.contentHorizontalAlignment = .Left;
        closeButton!.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        closeButton!.titleLabel?.font = UIFont.systemFontOfSize(15)
        closeButton!.setTitleColor(UIColor(white:0.56, alpha:1.0), forState: .Highlighted);
        closeButton!.addTarget(self, action:#selector(SecondPasswordViewController.close(_:)), forControlEvents: UIControlEvents.TouchUpInside);
        topBar!.addSubview(closeButton!);
        
        closeButton!.frame = CGRectMake(self.view.frame.size.width - 80, 15, 80, 51);
        closeButton!.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        closeButton!.contentHorizontalAlignment = .Right
        closeButton!.titleLabel?.adjustsFontSizeToFitWidth = true
        closeButton!.setTitle(NSLocalizedString("Close", comment: ""), forState: .Normal)
        closeButton!.setImage(nil, forState: .Normal)
        
        password?.returnKeyType = .Done
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        password?.becomeFirstResponder()
    }

    @IBAction func done(sender: UIButton) {
        checkSecondPassword()
    }
    
    @IBAction func close(sender: UIButton) {
        password?.resignFirstResponder()
        delegate!.returnToRootViewController { () -> Void in
            self.dismissViewControllerAnimated(true, completion: nil)
        }
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
                // if we are verifying backup, go to verify words view controller
                self.navigationController?.performSegueWithIdentifier("backupVerify", sender: nil)
            }
                self.dismissViewControllerAnimated(true, completion: nil)
        } else {
            alertUserWithErrorMessage((NSLocalizedString("Second Password Incorrect", comment: "")))
        }
    }
    
    func alertUserWithErrorMessage(message : String) {
        let alert = UIAlertController(title:  NSLocalizedString("Error", comment:""), message: message, preferredStyle: .Alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:""), style: .Default, handler: { (UIAlertAction) -> Void in
             self.password?.text = ""
        }))
        NSNotificationCenter.defaultCenter().addObserver(alert, selector: #selector(UIViewController.autoDismiss), name: "reloadToDismissViews", object: nil)
        presentViewController(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(textField: UITextField) -> Bool {
        checkSecondPassword()
        return true
    }
    
}

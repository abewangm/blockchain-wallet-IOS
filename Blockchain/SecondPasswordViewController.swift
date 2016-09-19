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
    func returnToRootViewController(_ completionHandler: @escaping () -> Void ) -> Void
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
        
        topBar = UIView(frame:CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: Constants.Measurements.DefaultHeaderHeight));
        topBar!.backgroundColor = Constants.Colors.BlockchainBlue
        self.view.addSubview(topBar!);
        
        let headerLabel = UILabel(frame:CGRect(x: 80, y: 20.5, width: self.view.frame.size.width - 160, height: 40));
        headerLabel.font = UIFont.systemFont(ofSize: 13.0)
        headerLabel.textColor = UIColor.white
        headerLabel.textAlignment = .center;
        headerLabel.adjustsFontSizeToFitWidth = true;
        headerLabel.text = NSLocalizedString("Second Password Required", comment: "");
        topBar!.addSubview(headerLabel);
        
        closeButton = UIButton(type: UIButtonType.custom)
        closeButton!.contentHorizontalAlignment = .left;
        closeButton!.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        closeButton!.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        closeButton!.setTitleColor(UIColor(white:0.56, alpha:1.0), for: .highlighted);
        closeButton!.addTarget(self, action:#selector(SecondPasswordViewController.close(_:)), for: UIControlEvents.touchUpInside);
        topBar!.addSubview(closeButton!);
        
        closeButton!.frame = CGRect(x: self.view.frame.size.width - 80, y: 15, width: 80, height: 51);
        closeButton!.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
        closeButton!.contentHorizontalAlignment = .right
        closeButton!.titleLabel?.adjustsFontSizeToFitWidth = true
        closeButton!.setTitle(NSLocalizedString("Close", comment: ""), for: UIControlState())
        closeButton!.setImage(nil, for: UIControlState())
        
        password?.returnKeyType = .done
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        password?.becomeFirstResponder()
    }

    @IBAction func done(_ sender: UIButton) {
        checkSecondPassword()
    }
    
    @IBAction func close(_ sender: UIButton) {
        password?.resignFirstResponder()
        delegate!.returnToRootViewController { () -> Void in
            self.dismiss(animated: true, completion: nil)
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
                self.navigationController?.performSegue(withIdentifier: "backupVerify", sender: nil)
            }
                self.dismiss(animated: true, completion: nil)
        } else {
            alertUserWithErrorMessage((NSLocalizedString("Second Password Incorrect", comment: "")))
        }
    }
    
    func alertUserWithErrorMessage(_ message : String) {
        let alert = UIAlertController(title:  NSLocalizedString("Error", comment:""), message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: NSLocalizedString("OK", comment:""), style: .default, handler: { (UIAlertAction) -> Void in
             self.password?.text = ""
        }))
        NotificationCenter.default.addObserver(alert, selector: #selector(UIViewController.autoDismiss), name: NSNotification.Name(rawValue: "reloadToDismissViews"), object: nil)
        present(alert, animated: true, completion: nil)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        checkSecondPassword()
        return true
    }
    
}

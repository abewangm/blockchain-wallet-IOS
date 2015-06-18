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

class SecondPasswordViewController: UIViewController {

    @IBOutlet weak var navigationBar: UINavigationBar?
    @IBOutlet weak var password: UITextField?

    
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
        if let theDelegate = delegate {
            theDelegate.didGetSecondPassword(password!.text)
        }
        
        self.performSegueWithIdentifier("unwindSecondPassword", sender: self)
    }


}

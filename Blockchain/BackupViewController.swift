//
//  BackupViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 19-05-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BackupViewController: UIViewController {
    
    //    @IBOutlet  weak var someButton: UIButton?
    

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.clearColor()
        
        let closeButton = UIBarButtonItem(title: "Close", style: .Plain, target: self, action: "close:")
        closeButton.tintColor = UIColor.whiteColor()
        
        self.navigationItem.setRightBarButtonItem(closeButton, animated: false)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func close(sender: UIBarButtonItem) {
        // Using a notification until more of the app is written in Swift.
        NSNotificationCenter.defaultCenter().postNotificationName("CloseBackupScreen", object: nil)
    }
}

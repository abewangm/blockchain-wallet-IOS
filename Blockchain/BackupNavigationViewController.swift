//
//  BackupNavigationViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 17-06-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

@objc class BackupNavigationViewController: UINavigationController {

    var wallet : Wallet?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // No seperator:
        UINavigationBar.appearance().setBackgroundImage(UIImage.new(), forBarMetrics: UIBarMetrics.Default)
        UINavigationBar.appearance().shadowImage = UIImage.new()
        
        let backupViewController = self.viewControllers.first as! BackupViewController
        backupViewController.wallet = self.wallet
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

}

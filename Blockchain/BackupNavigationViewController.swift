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
    
    var backButtonCreated : Bool = false
    var closeButton : UIButton?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationBar.backgroundColor = Constants.Colors.BlockchainBlue
        self.navigationItem.title = NSLocalizedString("Backup Wallet", comment: "");
        self.navigationBar.titleTextAttributes = [NSFontAttributeName:  UIFont.systemFontOfSize(17), NSForegroundColorAttributeName: UIColor.whiteColor()]
     
        let backupViewController = self.viewControllers.first as! BackupViewController
        backupViewController.wallet = self.wallet
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if (viewControllers.count == 1 && !backButtonCreated) {
            closeButton = UIButton.buttonWithType(UIButtonType.Custom) as? UIButton
            closeButton!.frame = CGRectMake(12, 0, 80, 46);
            closeButton!.contentHorizontalAlignment = .Left;
            closeButton!.titleLabel?.font = UIFont.boldSystemFontOfSize(15)
            closeButton!.setTitle(NSLocalizedString("Close", comment: ""), forState: .Normal);
            closeButton!.setTitleColor(UIColor(white:0.56, alpha:1.0), forState: .Highlighted);
            closeButton!.addTarget(self, action:"closeButtonClicked", forControlEvents: UIControlEvents.TouchUpInside);
            navigationBar.addSubview(closeButton!);
            backButtonCreated = true
        } else {
            closeButton!.removeFromSuperview()
            backButtonCreated = false
        }
    }
    
    func closeButtonClicked() {
        dismissViewControllerAnimated(true, completion: nil)
    }
}

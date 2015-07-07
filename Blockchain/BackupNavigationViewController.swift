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
    
    var isTransitioning : Bool = false {
        didSet {
            if isTransitioning == true {
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: "finishTransitioning", userInfo: nil, repeats: false)
            }
        }
    }
    
    func finishTransitioning() {
       isTransitioning = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        var topBar = UIView(frame:CGRectMake(0, 0, self.view.frame.size.width, Constants.Measurements.DefaultHeaderHeight));
        topBar.backgroundColor = Constants.Colors.BlockchainBlue
        self.view.addSubview(topBar);
        
        var headerLabel = UILabel(frame:CGRectMake(80, 17.5, self.view.frame.size.width - 160, 40));
        headerLabel.font = UIFont.systemFontOfSize(22.0)
        headerLabel.textColor = UIColor.whiteColor()
        headerLabel.textAlignment = .Center;
        headerLabel.adjustsFontSizeToFitWidth = true;
        headerLabel.text = NSLocalizedString("Backup Wallet", comment: "");
        topBar.addSubview(headerLabel);
        
        var backButton : UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
        backButton.frame = CGRectMake(0, 12, 85, 51);
        backButton.contentHorizontalAlignment = .Left;
        backButton.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        backButton.titleLabel?.font = UIFont.systemFontOfSize(15)
        backButton.setImage(UIImage(named:"back_chevron_icon"), forState: .Normal);
        backButton.setTitleColor(UIColor(white:0.56, alpha:1.0), forState: .Highlighted);
        backButton.addTarget(self, action:"backButtonClicked", forControlEvents: UIControlEvents.TouchUpInside);
        topBar.addSubview(backButton);
        
        let backupViewController = self.viewControllers.first as! BackupViewController
        backupViewController.wallet = self.wallet
    }
    
    func backButtonClicked() {
        if let currentViewController = self.visibleViewController {
            if (!isTransitioning) {
                if (currentViewController.isMemberOfClass(BackupViewController)) {
                    NSNotificationCenter.defaultCenter().postNotificationName("CloseBackupScreen", object: nil)
                } else {
                    popViewControllerAnimated(true);
                }
                isTransitioning = true
            }
        }
    }
}

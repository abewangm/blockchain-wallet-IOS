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
    var topBar : UIView?
    var closeButton : UIButton?
    // TODOBackup: Use native back button
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
        
        topBar = UIView(frame:CGRectMake(0, 0, self.view.frame.size.width, Constants.Measurements.DefaultHeaderHeight));
        topBar!.backgroundColor = Constants.Colors.BlockchainBlue
        self.view.addSubview(topBar!);
        
        var headerLabel = UILabel(frame:CGRectMake(80, 17.5, self.view.frame.size.width - 160, 40));
        headerLabel.font = UIFont.systemFontOfSize(22.0)
        headerLabel.textColor = UIColor.whiteColor()
        headerLabel.textAlignment = .Center;
        headerLabel.adjustsFontSizeToFitWidth = true;
        headerLabel.text = NSLocalizedString("Backup Funds", comment: "");
        topBar!.addSubview(headerLabel);
        
        closeButton = UIButton.buttonWithType(UIButtonType.Custom) as? UIButton
        closeButton!.contentHorizontalAlignment = .Left;
        closeButton!.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        closeButton!.titleLabel?.font = UIFont.systemFontOfSize(15)
        closeButton!.setTitleColor(UIColor(white:0.56, alpha:1.0), forState: .Highlighted);
        closeButton!.addTarget(self, action:"backButtonClicked", forControlEvents: UIControlEvents.TouchUpInside);
        topBar!.addSubview(closeButton!);
        
        let backupViewController = self.viewControllers.first as! BackupViewController
        backupViewController.wallet = self.wallet
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (viewControllers.count == 1) {
            closeButton!.frame = CGRectMake(8, 15, 85, 51);
            closeButton!.setTitle(NSLocalizedString("Close", comment: ""), forState: .Normal)
            closeButton!.setImage(nil, forState: .Normal)
        } else {
            closeButton!.frame = CGRectMake(0, 12, 85, 51);
            closeButton!.setTitle("", forState: .Normal)
            closeButton!.setImage(UIImage(named:"back_chevron_icon"), forState: .Normal);
        }
    }
    
    func backButtonClicked() {
        if (!isTransitioning) {
            if (viewControllers.count == 1) {
                    dismissViewControllerAnimated(true, completion: nil)
                } else {
                    popViewControllerAnimated(true);
                }
            isTransitioning = true
            }
        }
}

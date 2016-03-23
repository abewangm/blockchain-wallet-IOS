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
                NSTimer.scheduledTimerWithTimeInterval(0.5, target: self, selector: #selector(BackupNavigationViewController.finishTransitioning), userInfo: nil, repeats: false)
            }
        }
    }
    var busyView : BCFadeView?
    
    func finishTransitioning() {
       isTransitioning = false
    }
    
    internal func reload() {
        self.popToRootViewControllerAnimated(true)
        busyView?.fadeOut()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topBar = UIView(frame:CGRectMake(0, 0, self.view.frame.size.width, Constants.Measurements.DefaultHeaderHeight));
        topBar!.backgroundColor = Constants.Colors.BlockchainBlue
        self.view.addSubview(topBar!);
        
        let headerLabel = UILabel(frame:CGRectMake(80, 17.5, self.view.frame.size.width - 160, 40));
        headerLabel.font = UIFont.systemFontOfSize(22.0)
        headerLabel.textColor = UIColor.whiteColor()
        headerLabel.textAlignment = .Center;
        headerLabel.adjustsFontSizeToFitWidth = true;
        headerLabel.text = NSLocalizedString("Backup Funds", comment: "");
        topBar!.addSubview(headerLabel);
        
        closeButton = UIButton(type: UIButtonType.Custom)
        closeButton!.contentHorizontalAlignment = .Left;
        closeButton!.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        closeButton!.titleLabel?.font = UIFont.systemFontOfSize(15)
        closeButton!.setTitleColor(UIColor(white:0.56, alpha:1.0), forState: .Highlighted);
        closeButton!.addTarget(self, action:#selector(BackupNavigationViewController.backButtonClicked), forControlEvents: UIControlEvents.TouchUpInside);
        topBar!.addSubview(closeButton!);
        
        let backupViewController = self.viewControllers.first as! BackupViewController
        backupViewController.wallet = self.wallet
        
        busyView = BCFadeView(frame: view.frame)
        busyView?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        let textWithSpinnerView = UIView(frame:CGRectMake(0, 0, 250, 110))
        textWithSpinnerView.backgroundColor = UIColor.whiteColor()
        busyView!.addSubview(textWithSpinnerView);
        textWithSpinnerView.center = busyView!.center;
        
        let busyLabel = UILabel(frame:CGRectMake(0, 0, Constants.Measurements.BusyViewLabelWidth, Constants.Measurements.BusyViewLabelHeight))
        busyLabel.font = UIFont.systemFontOfSize(Constants.Measurements.BusyViewLabelFontSystemSize);
        busyLabel.alpha = Constants.Measurements.BusyViewLabelAlpha;
        busyLabel.adjustsFontSizeToFitWidth = true;
        busyLabel.textAlignment = .Center
        busyLabel.text = NSLocalizedString("Syncing Wallet", comment: "");
        busyLabel.center = CGPointMake(textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 + 15);
        textWithSpinnerView.addSubview(busyLabel);
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .Gray)
        spinner.center = CGPointMake(textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 - 15);
        textWithSpinnerView.addSubview(spinner);
        textWithSpinnerView.bringSubviewToFront(spinner);
        spinner.startAnimating();
        
        busyView!.containerView = textWithSpinnerView;
        busyView!.fadeOut();
        
        view.addSubview(busyView!);
        view.bringSubviewToFront(busyView!);
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: #selector(BackupNavigationViewController.reload), name: "reloadSettingsAndSecurityCenter", object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (viewControllers.count == 1) {
            closeButton!.frame = CGRectMake(self.view.frame.size.width - 80, 15, 80, 51);
            closeButton!.titleEdgeInsets = UIEdgeInsetsMake(0.0, 10.0, 0.0, 10.0);
            closeButton!.contentHorizontalAlignment = .Right
            closeButton!.titleLabel?.adjustsFontSizeToFitWidth = true
            closeButton!.setTitle(NSLocalizedString("Close", comment: ""), forState: .Normal)
            closeButton!.setImage(nil, forState: .Normal)
        } else {
            closeButton!.frame = CGRectMake(0, 12, 85, 51);
            closeButton!.setTitle("", forState: .Normal)
            closeButton!.contentHorizontalAlignment = .Left
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
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
}

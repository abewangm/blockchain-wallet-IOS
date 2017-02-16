//
//  BackupNavigationViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 17-06-15.
//  Copyright (c) 2015 Blockchain Luxembourg S.A. All rights reserved.
//

import UIKit

@objc class BackupNavigationViewController: UINavigationController {

    var app : RootService?
    var wallet : Wallet?
    var topBar : UIView?
    var closeButton : UIButton?
    // TODOBackup: Use native back button
    var isTransitioning : Bool = false {
        didSet {
            if isTransitioning == true {
                Timer.scheduledTimer(timeInterval: 0.5, target: self, selector: #selector(BackupNavigationViewController.finishTransitioning), userInfo: nil, repeats: false)
            }
        }
    }
    var busyView : BCFadeView?
    var headerLabel: UILabel?
    
    func finishTransitioning() {
       isTransitioning = false
    }
    
    internal func reload() {
        self.popToRootViewController(animated: true)
        busyView?.fadeOut()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        topBar = UIView(frame:CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: Constants.Measurements.DefaultHeaderHeight));
        topBar!.backgroundColor = Constants.Colors.BlockchainBlue
        self.view.addSubview(topBar!);
        
        headerLabel = UILabel(frame:CGRect(x: 80, y: 17.5, width: self.view.frame.size.width - 160, height: 40));
        headerLabel?.font = UIFont(name:"Montserrat-Regular", size: 20)
        headerLabel?.textColor = UIColor.white
        headerLabel?.textAlignment = .center;
        headerLabel?.adjustsFontSizeToFitWidth = true;
        headerLabel?.text = NSLocalizedString("Backup Funds", comment: "");
        topBar!.addSubview(headerLabel!);
        
        closeButton = UIButton(type: UIButtonType.custom)
        closeButton!.contentHorizontalAlignment = .left;
        closeButton!.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
        closeButton!.titleLabel?.font = UIFont.systemFont(ofSize: 15)
        closeButton!.setTitleColor(UIColor(white:0.56, alpha:1.0), for: .highlighted);
        closeButton!.addTarget(self, action:#selector(BackupNavigationViewController.backButtonClicked), for: UIControlEvents.touchUpInside);
        topBar!.addSubview(closeButton!);
        
        let backupViewController = self.viewControllers.first as! BackupViewController
        backupViewController.wallet = self.wallet
        backupViewController.app = self.app
        
        busyView = BCFadeView(frame: view.frame)
        busyView?.backgroundColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.5)
        let textWithSpinnerView = UIView(frame:CGRect(x: 0, y: 0, width: 250, height: 110))
        textWithSpinnerView.backgroundColor = UIColor.white
        busyView!.addSubview(textWithSpinnerView);
        textWithSpinnerView.center = busyView!.center;
        
        let busyLabel = UILabel(frame:CGRect(x: 0, y: 0, width: Constants.Measurements.BusyViewLabelWidth, height: Constants.Measurements.BusyViewLabelHeight))
        busyLabel.font = UIFont(name:"Montserrat-Regular", size: Constants.Measurements.BusyViewLabelFontSystemSize);
        busyLabel.alpha = Constants.Measurements.BusyViewLabelAlpha;
        busyLabel.adjustsFontSizeToFitWidth = true;
        busyLabel.textAlignment = .center
        busyLabel.text = NSLocalizedString("Syncing Wallet", comment: "");
        busyLabel.center = CGPoint(x: textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, y: textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 + 15);
        textWithSpinnerView.addSubview(busyLabel);
        
        let spinner = UIActivityIndicatorView(activityIndicatorStyle: .gray)
        spinner.center = CGPoint(x: textWithSpinnerView.bounds.origin.x + textWithSpinnerView.bounds.size.width/2, y: textWithSpinnerView.bounds.origin.y + textWithSpinnerView.bounds.size.height/2 - 15);
        textWithSpinnerView.addSubview(spinner);
        textWithSpinnerView.bringSubview(toFront: spinner);
        spinner.startAnimating();
        
        busyView!.containerView = textWithSpinnerView;
        busyView!.fadeOut();
        
        view.addSubview(busyView!);
        view.bringSubview(toFront: busyView!);
        
        NotificationCenter.default.addObserver(self, selector: #selector(BackupNavigationViewController.reload), name: NSNotification.Name(rawValue: "reloadToDismissViews"), object: nil)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        if (viewControllers.count == 1) {
            closeButton!.frame = CGRect(x: self.view.frame.size.width - 80, y: 15, width: 80, height: 51);
            closeButton!.imageEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 20);
            closeButton!.contentHorizontalAlignment = .right
            closeButton!.center = CGPoint(x: closeButton!.center.x, y: headerLabel!.center.y);
            closeButton!.setImage(UIImage(named:"close"), for: UIControlState())
        } else {
            closeButton!.frame = CGRect(x: 0, y: 12, width: 85, height: 51);
            closeButton!.setTitle("", for: UIControlState())
            closeButton!.contentHorizontalAlignment = .left
            closeButton!.setImage(UIImage(named:"back_chevron_icon"), for: UIControlState());
        }
    }
    
    func backButtonClicked() {
        if (!isTransitioning) {
            if (viewControllers.count == 1) {
                    dismiss(animated: true, completion: nil)
                } else {
                    popViewController(animated: true);
                }
            isTransitioning = true
            }
        }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}

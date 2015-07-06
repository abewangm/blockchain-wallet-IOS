//
//  BackupViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 19-05-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BackupViewController: UIViewController {
    
    @IBOutlet weak var summaryLabel: UILabel?
    @IBOutlet weak var backupWalletButton: UIButton?
    @IBOutlet weak var explanation: UILabel?
    
    var wallet : Wallet?

    override func viewDidLoad() {
        super.viewDidLoad()
        

        
//        var closeButton = UIButton(frame:CGRectMake(self.view.frame.size.width - 70, 15, 80, 51));
//        closeButton.setTitle(NSLocalizedString("Close", comment: ""), forState: .Normal);
//        closeButton.setTitleColor(UIColor(white: 0.56, alpha: 1.0), forState: .Highlighted);
//        closeButton.titleLabel!.font = UIFont.systemFontOfSize(15);
//        closeButton.addTarget(self, action:@selector(close:), forControlEvents: .TouchUpInside];
//        topBar.addSubview(closeButton);
//        
//        var backButton : UIButton = UIButton.buttonWithType(UIButtonType.Custom) as! UIButton
//        backButton.frame = CGRectMake(0, 12, 85, 51);
//        backButton.contentHorizontalAlignment = .Left;
//        backButton.contentEdgeInsets = UIEdgeInsetsMake(0, 4, 0, 0);
//        backButton.titleLabel?.font = UIFont.systemFontOfSize(15)
//        backButton.setImage(UIImage(named:"back_chevron_icon"), forState: .Normal);
//        backButton.setTitleColor(UIColor(white:0.56, alpha:1.0), forState: .Highlighted);
//        backButton.addTarget(self, action:@selector(backButtonClicked:), forControlEvents: .TouchUpInside);
//        [backButton setHidden:YES];
//        [topBar addSubview:backButton];
        
        let closeButton = UIBarButtonItem(title: "Close", style: .Plain, target: self, action: "close:")
        closeButton.tintColor = UIColor.whiteColor()
        
        self.navigationItem.setRightBarButtonItem(closeButton, animated: false)
    
        backupWalletButton?.clipsToBounds = true
        backupWalletButton?.layer.cornerRadius = 15
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        if wallet!.isRecoveryPhraseVerified() {
            summaryLabel!.text = "You backed up your wallet."
            explanation!.text = "You only need to backup your wallet once."
        }
    }
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        let vc = segue.destinationViewController as! BackupWordsViewController
        vc.wallet = wallet
    }
    
    @IBAction func unwindSecondPasswordCancel(segue: UIStoryboardSegue) {
    }
    
    @IBAction func unwindVerifyWords(segue: UIStoryboardSegue) {
    }
}
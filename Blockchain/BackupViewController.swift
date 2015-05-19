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

        // Do any additional setup after loading the view.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    @IBAction func backupWalletPressed(sender: UIButton) {
        let vc = BackupWordsViewController(nibName: "BackupWords", bundle:NSBundle.mainBundle())
        self.navigationController?.pushViewController(vc, animated: true)
    }
}

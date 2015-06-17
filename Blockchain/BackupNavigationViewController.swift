//
//  BackupNavigationViewController.swift
//  Blockchain
//
//  Created by Sjors Provoost on 17-06-15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BackupNavigationViewController: UINavigationController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // No seperator:
        UINavigationBar.appearance().setBackgroundImage(UIImage.new(), forBarMetrics: UIBarMetrics.Default)
        UINavigationBar.appearance().shadowImage = UIImage.new()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

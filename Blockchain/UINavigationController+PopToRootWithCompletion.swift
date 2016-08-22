//
//  UINavigationController+PopToRootWithCompletion.swift
//  Blockchain
//
//  Created by Kevin Wu on 12/22/15.
//  Copyright © 2015 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation

extension UINavigationController {
    func popToRootViewControllerWithHandler(completion: ()->()) {
        CATransaction.begin()
        CATransaction.setCompletionBlock(completion)
        self.popToRootViewControllerAnimated(true)
        CATransaction.commit()
    }
}

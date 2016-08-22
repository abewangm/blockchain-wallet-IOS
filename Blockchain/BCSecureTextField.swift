//
//  BCSecureTextField.swift
//  Blockchain
//
//  Created by Kevin Wu on 8/14/15.
//  Copyright (c) 2015 Blockchain Luxembourg S.A. All rights reserved.
//

import UIKit

class BCSecureTextField : UITextField {
    
    init() {
        super.init(frame: CGRectZero)
        autocorrectionType = .No
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        autocorrectionType = .No
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        autocorrectionType = .No
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        autocorrectionType = .No
    }
}

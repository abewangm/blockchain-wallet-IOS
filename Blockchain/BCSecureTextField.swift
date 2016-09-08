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
        super.init(frame: CGRect.zero)
        autocorrectionType = .no
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        autocorrectionType = .no
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        autocorrectionType = .no
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        autocorrectionType = .no
    }
}

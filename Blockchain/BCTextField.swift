//
//  BCTextField.swift
//  Blockchain
//
//  Created by Mark Pfluger on 6/26/15.
//  Copyright (c) 2015 Blockchain Luxembourg S.A. All rights reserved.
//

import UIKit

class BCTextField: BCSecureTextField {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        setupOnePixelLine()
    }
    
    override var frame: CGRect {
        didSet {
            setupOnePixelLine()
        }
    }
    
    func setupOnePixelLine() {
        if (self.superview == nil) {
            return
        }
        
        let onePixelHeight = 1.0/UIScreen.main.scale
        let onePixelLine = UIView(frame: CGRect(x: 0, y: self.frame.size.height - onePixelHeight,
            width: self.frame.size.width + 15, height: onePixelHeight))
        
        onePixelLine.frame = self.superview!.convert(onePixelLine.frame, from: self)
        
        onePixelLine.isUserInteractionEnabled = false
        onePixelLine.backgroundColor = Constants.Colors.TextFieldBorderGray
        
        self.superview!.addSubview(onePixelLine)
    }
}

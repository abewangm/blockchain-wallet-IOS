//
//  BCTextField.swift
//  Blockchain
//
//  Created by Mark Pfluger on 6/26/15.
//  Copyright (c) 2015 Qkos Services Ltd. All rights reserved.
//

import UIKit

class BCTextField: BCSecureTextField {

    override func awakeFromNib() {
        super.awakeFromNib()
        
        if (self.superview == nil) {
            return
        }
        
        var onePixelHeight = 1.0/UIScreen.mainScreen().scale
        var onePixelLine = UIView(frame: CGRectMake(0, self.frame.size.height - onePixelHeight,
            self.frame.size.width + 15, onePixelHeight))
        
        onePixelLine.frame = self.superview!.convertRect(onePixelLine.frame, fromView: self)
        
        onePixelLine.userInteractionEnabled = false
        onePixelLine.backgroundColor = Constants.Colors.TextFieldBorderGray
        
        self.superview!.addSubview(onePixelLine)
    }
}
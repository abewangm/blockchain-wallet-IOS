//
//  BCChartMarkerView.swift
//  Blockchain
//
//  Created by kevinwu on 10/30/17.
//  Copyright © 2017 Blockchain Luxembourg S.A. All rights reserved.
//

import Foundation
import Charts

class BCChartMarkerView : MarkerView
{
    var dateLabel = UILabel()
    var priceLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        let font = UIFont(name: "Montserrat-Regular", size: Constants.FontSizes.Medium);
        dateLabel.frame = CGRect(x: 0, y: 0, width: self.bounds.size.width, height: self.bounds.size.height/2)
        dateLabel.font = font
        priceLabel.frame = dateLabel.frame.offsetBy(dx: 0, dy: self.bounds.size.height/2)
        priceLabel.font = font
        self.addSubview(priceLabel)
        self.addSubview(dateLabel)
        self.backgroundColor = Constants.Colors.TextFieldBorderGray
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    override func offsetForDrawing(atPoint point: CGPoint) -> CGPoint {
        
        let leftEdge : CGFloat = 90.0
        let rightEdge : CGFloat = 240.0
        
        var x = -(self.bounds.size.width/2)
        if point.x < leftEdge {
            x += leftEdge - point.x
        } else if point.x > rightEdge {
            x -= point.x - rightEdge
        }

        return CGPoint(x: x, y: -(self.bounds.size.height/2))
    }
    
    override func refreshContent(entry: ChartDataEntry, highlight: Highlight) {
        super.refreshContent(entry: entry, highlight: highlight)
        dateLabel.text = "\(dateFromTimeInterval(timeInterval: entry.x))"
        priceLabel.text = "\(entry.y)"
        self.isHidden = false
    }
    
    private func dateFromTimeInterval(timeInterval: TimeInterval) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "E, MMM dd, HH:mm"
        let date = Date(timeIntervalSince1970: timeInterval)
        return dateFormatter.string(from: date)
    }
}

//
//  NCThinLineView.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

@IBDesignable
class NCThinLineView: UIView {
	
	override func draw(_ rect: CGRect) {
		let path = UIBezierPath()
		path.move(to: rect.origin)
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.origin.y))
		path.lineWidth = 1.0 / UIScreen.main.scale
		tintColor.setStroke()
		path.stroke()
	}
	
}

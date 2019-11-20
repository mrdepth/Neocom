//
//  ThinLineView.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

@IBDesignable
class ThinLineView: UIView {
	
	override func draw(_ rect: CGRect) {
		let path = UIBezierPath()
		path.move(to: rect.origin)
		path.addLine(to: CGPoint(x: rect.maxX, y: rect.origin.y))
		path.lineWidth = 1.0 / UIScreen.main.scale
		tintColor.setStroke()
		path.stroke()
	}
	
}

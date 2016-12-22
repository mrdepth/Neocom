//
//  NCMarketHistoryView.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

//@IBDesignable
class NCMarketHistoryView: UIView {
	var donchian: UIBezierPath?
	var volume: UIBezierPath?
	var median: UIBezierPath?
	
	override func prepareForInterfaceBuilder() {
	}
	
	override func draw(_ rect: CGRect) {
		guard let donchian = donchian?.copy() as? UIBezierPath,
			let volume = volume?.copy() as? UIBezierPath,
			let avg = median?.copy() as? UIBezierPath
			else {
				return
		}
		
		
		
		var transform = CGAffineTransform.identity
		var rect = volume.bounds
		if rect.size.width > 0 && rect.size.height > 0 {
			transform = transform.scaledBy(x: 1, y: -1)
			transform = transform.translatedBy(x: 0, y: -bounds.size.height)
			transform = transform.scaledBy(x: bounds.size.width / rect.size.width, y: bounds.size.height / rect.size.height * 0.33)
			transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
			volume.apply(transform)
		}
		
		
		rect = donchian.bounds.union(avg.bounds)
		//rect = avg.bounds
		if rect.size.width > 0 && rect.size.height > 0 {
			transform = CGAffineTransform.identity
			transform = transform.scaledBy(x: 1, y: -1)
			transform = transform.translatedBy(x: 0, y: -bounds.size.height * 0.66)
			transform = transform.scaledBy(x: bounds.size.width / rect.size.width, y: bounds.size.height / rect.size.height * 0.66)
			transform = transform.translatedBy(x: -rect.origin.x, y: -rect.origin.y)
			donchian.apply(transform)
			avg.apply(transform)
		}
		
		UIColor(number: 0x003f4fff).setFill()
		volume.fill()
		UIColor(number: 0x282f37ff).setFill()
		donchian.fill()

		UIColor.caption.setStroke()
		avg.stroke()
		
		
		let dy = self.bounds.size.height / 8.0
		var y = 0 as CGFloat
		let grid = UIBezierPath()
		while y <= self.bounds.size.height {
			grid.move(to: CGPoint(x: 0, y: y))
			grid.addLine(to: CGPoint(x: bounds.size.width, y: y))
			y += dy
		}
		var x = 0 as CGFloat
		while x <= self.bounds.size.width {
			grid.move(to: CGPoint(x: x, y: 0))
			grid.addLine(to: CGPoint(x: x, y: bounds.size.height))
			x += dy
		}
		
		UIColor(white: 1.0, alpha: 0.1).setStroke()
		grid.stroke()
	}
}

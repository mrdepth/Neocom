//
//  NCResourceLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

@IBDesignable
class NCResourceLabel: NCLabel {
	var maximumValue: Float = 0 {
		didSet {
			updateText()
		}
	}
	
	var value: Float = 0 {
		didSet {
			updateText()
		}
	}

	lazy var formatter: NCUnitFormatter = NCUnitFormatter()
	
	override func awakeFromNib() {
		super.awakeFromNib()
		var rgba: [CGFloat] = [0, 0, 0, 0]
		self.tintColor.getRed(&rgba[0], green: &rgba[1], blue: &rgba[2], alpha: &rgba[3])
		self.backgroundColor = UIColor(red: rgba[0] * 0.4, green: rgba[1] * 0.4, blue: rgba[2] * 0.4, alpha: rgba[3])
	}
	
	
	
	#if TARGET_INTERFACE_BUILDER
	override func prepareForInterfaceBuilder() {
	self.awakeFromNib()
	}
	#endif
	
	override func draw(_ rect: CGRect) {
#if TARGET_INTERFACE_BUILDER
		let progress = 0.5
#else
		let progress = maximumValue > 0 ? value / maximumValue : 0.0
#endif
		let context = UIGraphicsGetCurrentContext()
		context?.saveGState()
		var left = rect
		left.size.width *= CGFloat(progress)
		tintColor.setFill()
		context?.fill(left)
		context?.restoreGState()
		super.draw(rect)
	}
	
	private func updateText() {
//		let a = NCUnitFormatter.localizedString(from: maximumValue, unit: .none, style: <#T##NCUnitFormatter.Style#>, useSIPrefix: <#T##Bool#>)
//		text = "\(a)/(b)"
	}
}

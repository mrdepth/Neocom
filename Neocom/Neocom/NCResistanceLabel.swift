//
//  NCResistanceLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

enum NCResistance: Int {
	case em
	case thermal
	case kinetic
	case explosive
}

@IBDesignable
class NCResistanceLabel: NCLabel {
	@IBInspectable var value: Float = 0 {
		didSet {
			self.text = "\(Int(value * 100))%"
		}
	}
	@IBInspectable var resistance: Int = NCResistance.em.rawValue
	
	override func awakeFromNib() {
		super.awakeFromNib()
		switch NCResistance(rawValue: self.resistance) ?? .em {
		case .em:
			self.tintColor = UIColor(number: 0x3482C5FF)
		case .thermal:
			self.tintColor = UIColor(number: 0xC0262AFF)
		case .kinetic:
			self.tintColor = UIColor(number: 0xA3A3A3FF)
		case .explosive:
			self.tintColor = UIColor(number: 0xC2882AFF)
		}
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
		let context = UIGraphicsGetCurrentContext()
		context?.saveGState()
		var left = rect
		left.size.width *= CGFloat(value)
		tintColor.setFill()
		context?.fill(left)
		context?.restoreGState()
		super.draw(rect)
	}
}

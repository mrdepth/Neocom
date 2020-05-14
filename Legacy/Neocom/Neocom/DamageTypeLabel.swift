//
//  DamageTypeLabel.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

@IBDesignable
class DamageTypeLabel: UILabel {
	enum DamageType: Int {
		case em
		case thermal
		case kinetic
		case explosive
		
		var color: UIColor {
			switch self {
			case .em:
				return UIColor(number: 0x3482C5FF)
			case .thermal:
				return UIColor(number: 0xC0262AFF)
			case .kinetic:
				return UIColor(number: 0xA3A3A3FF)
			case .explosive:
				return UIColor(number: 0xC2882AFF)
			}
		}
		
		var image: UIImage {
			switch self {
			case .em:
				return #imageLiteral(resourceName: "em")
			case .thermal:
				return #imageLiteral(resourceName: "thermal")
			case .kinetic:
				return #imageLiteral(resourceName: "kinetic")
			case .explosive:
				return #imageLiteral(resourceName: "explosion")
			}
		}
	}
	
	@IBInspectable var progress: Float = 0 {
		didSet {
			setNeedsDisplay()
		}
	}
	@IBInspectable var damageType: Int = DamageType.em.rawValue
	
	override func awakeFromNib() {
		super.awakeFromNib()
		self.tintColor = (DamageType(rawValue: self.damageType) ?? .em).color

		backgroundColor = UIColor.clear
		var (r, g, b, a): (CGFloat, CGFloat, CGFloat, CGFloat) = (0, 0, 0, 0)
		tintColor.getRed(&r, green: &g, blue: &b, alpha: &a)

		self.dimingColor = UIColor(red: r * 0.4, green: b * 0.4, blue: b * 0.4, alpha: a)
		tintAdjustmentMode = .normal
	}
	
	var dimingColor: UIColor!
	
	
	#if TARGET_INTERFACE_BUILDER
	override func prepareForInterfaceBuilder() {
		self.awakeFromNib()
	}
	#endif
	
	override func draw(_ rect: CGRect) {
		let context = UIGraphicsGetCurrentContext()
		context?.saveGState()
		var left = rect
		left.size.width *= CGFloat(progress)
		var right = rect
		right.origin.x = left.maxX
		right.size.width -= left.size.width
		
		tintColor.setFill()
		context?.fill(left)
		
		dimingColor.setFill()
		context?.fill(right)
		
		context?.restoreGState()
		super.draw(rect)
	}
}

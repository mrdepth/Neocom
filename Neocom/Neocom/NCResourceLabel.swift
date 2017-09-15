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
	
	var maximumValue: Double = 0 {
		didSet {
			updateText()
		}
	}
	
	var value: Double = 0 {
		didSet {
			updateText()
		}
	}
	
	var unit: NCUnitFormatter.Unit = .none {
		didSet {
			shortFormatter = NCRangeFormatter(unit: unit, style: .short)
			fullFormatter = NCRangeFormatter(unit: unit, style: .full)
		}
	}
	
	lazy var shortFormatter: NCRangeFormatter = {
		return NCRangeFormatter(unit: self.unit, style: .short)
	}()
	lazy var fullFormatter: NCRangeFormatter = {
		return NCRangeFormatter(unit: self.unit, style: .full)
	}()
	
	override func awakeFromNib() {
		super.awakeFromNib()
		let rgba = UnsafeMutablePointer<CGFloat>.allocate(capacity: 4)
		defer {rgba.deallocate(capacity: 4)}
		self.tintColor.getRed(&rgba[0], green: &rgba[1], blue: &rgba[2], alpha: &rgba[3])
		self.backgroundColor = UIColor(red: rgba[0] * 0.4, green: rgba[1] * 0.4, blue: rgba[2] * 0.4, alpha: rgba[3])
		tintAdjustmentMode = .normal
	}
	
	
	
	#if TARGET_INTERFACE_BUILDER
	override func prepareForInterfaceBuilder() {
		self.awakeFromNib()
		updateText()
	}
	#endif
	
	override func draw(_ rect: CGRect) {
#if TARGET_INTERFACE_BUILDER
		let progress = 0.5
#else
		let progress = maximumValue > 0 ? (value / maximumValue).clamped(to: 0...1) : 0.0
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
		tintColor = value > maximumValue ? .red : UIColor(number: 0x009400ff)
		text = fullFormatter.string(for: value, maximum: maximumValue)
		let rect = textRect(forBounds: CGRect.infinite, limitedToNumberOfLines: 1)
		if bounds.size.width < rect.size.width {
			text = shortFormatter.string(for: value, maximum: maximumValue)
		}
	}
}

//
//  NCSegmentedControl.swift
//  Neocom
//
//  Created by Artem Shimanski on 09.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

@IBDesignable
class NCSegmentedControl: UISegmentedControl {

	override func awakeFromNib() {
		super.awakeFromNib()
		setup()
	}
	
#if TARGET_INTERFACE_BUILDER
	override func prepareForInterfaceBuilder() {
		setup()
	}
#endif
	
	override func draw(_ rect: CGRect) {
		super.draw(rect)
	}
	
	
	func setup() {
		setBackgroundImage(#imageLiteral(resourceName: "clear"), for: .normal, barMetrics: .default)
		setDividerImage(#imageLiteral(resourceName: "clear"), forLeftSegmentState: .normal, rightSegmentState: .normal, barMetrics: .default)
	}
}

//
//  TintImageView.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

@IBDesignable
class TintImageView: UIImageView {
	
	override func awakeFromNib() {
		let color = tintColor
		tintColor = nil
		tintColor = color
	}
	
	override var intrinsicContentSize: CGSize {
		return image != nil ? super.intrinsicContentSize : CGSize.zero
	}
	
	#if TARGET_INTERFACE_BUILDER
	override func prepareForInterfaceBuilder() {
		image = image?.withRenderingMode(.alwaysTemplate)
	}
	#endif
}

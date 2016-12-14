//
//  NCTintImageView.swift
//  Neocom
//
//  Created by Artem Shimanski on 14.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import Foundation

@IBDesignable
class NCTintImageView: UIImageView {
	override func awakeFromNib() {
		let color = tintColor
		tintColor = nil
		tintColor = color
	}
	
#if TARGET_INTERFACE_BUILDER
	override func prepareForInterfaceBuilder() {
		image = image?.withRenderingMode(.alwaysTemplate)
	}
#endif
}

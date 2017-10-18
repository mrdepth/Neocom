//
//  NCRoundedImageView.swift
//  Neocom
//
//  Created by Artem Shimanski on 13.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

//@IBDesignable
class NCRoundedImageView: NCImageView {
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.cornerRadius = bounds.size.width / 2
	}
}

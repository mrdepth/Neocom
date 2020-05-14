//
//  RoundedImageView.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
class RoundedImageView: UIImageView {
	
	override func layoutSubviews() {
		super.layoutSubviews()
		layer.cornerRadius = bounds.size.width / 2
	}
}

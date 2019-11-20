//
//  NCImageView.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCImageView: UIImageView {
	override var intrinsicContentSize: CGSize {
		if image == nil {
			return .zero
		}
		else {
			return super.intrinsicContentSize
		}
	}
}

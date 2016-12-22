//
//  NCMarketHistoryView.swift
//  Neocom
//
//  Created by Artem Shimanski on 22.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

//@IBDesignable
class NCMarketHistoryView: UIView {
	var chartImage: UIImage?
	
	override func prepareForInterfaceBuilder() {
	}
	
	override func draw(_ rect: CGRect) {
		chartImage?.draw(in: rect)
	}
}

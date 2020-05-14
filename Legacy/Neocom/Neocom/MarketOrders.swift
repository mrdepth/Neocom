//
//  MarketOrders.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/9/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MarketOrders: Assembly {
	typealias View = MarketOrdersViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.business.instantiateViewController(withIdentifier: "MarketOrdersViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


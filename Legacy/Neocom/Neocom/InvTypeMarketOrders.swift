//
//  InvTypeMarketOrders.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/26/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum InvTypeMarketOrders: Assembly {
	typealias View = InvTypeMarketOrdersViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "InvTypeMarketOrdersViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}

//
//  MarketQuickbar.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MarketQuickbar: Assembly {
	typealias View = MarketQuickbarViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "MarketQuickbarViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


//
//  InvMarketGroups.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum InvMarketGroups: Assembly {
	typealias View = InvMarketGroupsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		return _instantiate(input)
	}
	
	func instantiate() -> Future<View> {
		return _instantiate(nil)
	}
	
	private func _instantiate(_ input: View.Input?) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "InvMarketGroupsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}

}


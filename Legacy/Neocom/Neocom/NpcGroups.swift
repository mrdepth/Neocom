//
//  NpcGroups.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum NpcGroups: Assembly {
	typealias View = NpcGroupsViewController
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
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "NpcGroupsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


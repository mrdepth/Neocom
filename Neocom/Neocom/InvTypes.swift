//
//  InvTypes.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum InvTypes: Assembly {
	typealias View = InvTypesViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "InvTypesViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


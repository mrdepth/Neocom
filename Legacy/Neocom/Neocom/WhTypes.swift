//
//  WhTypes.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum WhTypes: Assembly {
	typealias View = WhTypesViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "WhTypesViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


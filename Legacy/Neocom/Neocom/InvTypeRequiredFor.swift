//
//  InvTypeRequiredFor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/1/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum InvTypeRequiredFor: Assembly {
	typealias View = InvTypeRequiredForViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "InvTypeRequiredForViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


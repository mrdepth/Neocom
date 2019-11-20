//
//  InvTypeMastery.swift
//  Neocom
//
//  Created by Artem Shimanski on 17/10/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum InvTypeMastery: Assembly {
	typealias View = InvTypeMasteryViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "InvTypeMasteryViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


//
//  FittingShips.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/23/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum FittingShips: Assembly {
	typealias View = FittingShipsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.fitting.instantiateViewController(withIdentifier: "FittingShipsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


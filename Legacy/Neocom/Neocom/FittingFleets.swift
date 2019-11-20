//
//  FittingFleets.swift
//  Neocom
//
//  Created by Artem Shimanski on 25/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum FittingFleets: Assembly {
	typealias View = FittingFleetsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.fitting.instantiateViewController(withIdentifier: "FittingFleetsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


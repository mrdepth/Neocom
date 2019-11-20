//
//  FittingMenu.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/23/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum FittingMenu: Assembly {
	typealias View = FittingMenuViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.fitting.instantiateViewController(withIdentifier: "FittingMenuViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


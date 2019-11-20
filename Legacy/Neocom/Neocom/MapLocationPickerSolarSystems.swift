//
//  MapLocationPickerSolarSystems.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MapLocationPickerSolarSystems: Assembly {
	typealias View = MapLocationPickerSolarSystemsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "MapLocationPickerSolarSystemsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}

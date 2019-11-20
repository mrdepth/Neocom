//
//  MapLocationPickerRecents.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MapLocationPickerRecents: Assembly {
	typealias View = MapLocationPickerRecentsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "MapLocationPickerRecentsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}

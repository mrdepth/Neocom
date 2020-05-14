//
//  MapLocationPickerSearchResults.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MapLocationPickerSearchResults: Assembly {
	typealias View = MapLocationPickerSearchResultsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "MapLocationPickerSearchResultsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}

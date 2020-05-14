//
//  DgmTypePickerTypes.swift
//  Neocom
//
//  Created by Artem Shimanski on 24/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum DgmTypePickerTypes: Assembly {
	typealias View = DgmTypePickerTypesViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.fitting.instantiateViewController(withIdentifier: "DgmTypePickerTypesViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


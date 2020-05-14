//
//  DgmTypePickerRecents.swift
//  Neocom
//
//  Created by Artem Shimanski on 25/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum DgmTypePickerRecents: Assembly {
	typealias View = DgmTypePickerRecentsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.fitting.instantiateViewController(withIdentifier: "DgmTypePickerRecentsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


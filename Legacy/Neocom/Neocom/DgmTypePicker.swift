//
//  DgmTypePicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum DgmTypePicker: Assembly {
	typealias View = DgmTypePickerViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.fitting.instantiateViewController(withIdentifier: "DgmTypePickerViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


//
//  DgmTypePickerContainer.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum DgmTypePickerContainer: Assembly {
	typealias View = DgmTypePickerContainerViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.fitting.instantiateViewController(withIdentifier: "DgmTypePickerContainerViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


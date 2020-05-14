//
//  DgmTypePickerGroups.swift
//  Neocom
//
//  Created by Artem Shimanski on 16/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum DgmTypePickerGroups: Assembly {
	typealias View = DgmTypePickerGroupsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.fitting.instantiateViewController(withIdentifier: "DgmTypePickerGroupsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


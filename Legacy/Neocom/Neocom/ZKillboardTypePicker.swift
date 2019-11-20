//
//  ZKillboardTypePicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum ZKillboardTypePicker: Assembly {
	typealias View = ZKillboardTypePickerViewController
	case `default`
	
	func instantiate(_ input: @escaping View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.killReports.instantiateViewController(withIdentifier: "ZKillboardTypePickerViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


//
//  DatePicker.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/20/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum DatePicker: Assembly {
	typealias View = DatePickerViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.killReports.instantiateViewController(withIdentifier: "DatePickerViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


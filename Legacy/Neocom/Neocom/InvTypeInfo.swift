//
//  InvTypeInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum InvTypeInfo: Assembly {
	typealias View = InvTypeInfoViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "InvTypeInfoViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}

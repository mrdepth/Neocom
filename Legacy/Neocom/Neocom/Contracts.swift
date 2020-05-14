//
//  Contracts.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum Contracts: Assembly {
	typealias View = ContractsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.business.instantiateViewController(withIdentifier: "ContractsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


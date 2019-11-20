//
//  ContractInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum ContractInfo: Assembly {
	typealias View = ContractInfoViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.business.instantiateViewController(withIdentifier: "ContractInfoViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


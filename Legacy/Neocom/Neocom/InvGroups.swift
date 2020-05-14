//
//  InvGroups.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum InvGroups: Assembly {
	typealias View = InvGroupsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<InvGroupsViewController> {
		switch self {
		case .default:
			let controller = UIStoryboard.database.instantiateViewController(withIdentifier: "InvGroupsViewController") as! InvGroupsViewController
			controller.input = input
			return .init(controller)
		}
	}
}

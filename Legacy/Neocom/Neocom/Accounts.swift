//
//  Accounts.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum Accounts: Assembly {
	case `default`
	
	func instantiate(_ input: Void) -> Future<AccountsViewController> {
		switch self {
		case .default:
			return .init(UIStoryboard.main.instantiateViewController(withIdentifier: "AccountsViewController") as! AccountsViewController)
		}
	}
}

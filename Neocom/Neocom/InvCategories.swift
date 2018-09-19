//
//  InvCategories.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum InvCategories: Assembly {
	case `default`
	
	func instantiate(_ input: Void) -> Future<InvCategoriesViewController> {
		switch self {
		case .default:
			return .init(UIStoryboard.database.instantiateViewController(withIdentifier: "InvCategoriesViewController") as! InvCategoriesViewController)
		}
	}
}

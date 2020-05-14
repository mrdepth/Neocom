//
//  ZKillboardInvCategories.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum ZKillboardInvCategories: Assembly {
	typealias View = ZKillboardInvCategoriesViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.killReports.instantiateViewController(withIdentifier: "ZKillboardInvCategoriesViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


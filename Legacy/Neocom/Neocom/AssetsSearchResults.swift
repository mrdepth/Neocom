//
//  AssetsSearchResults.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/8/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum AssetsSearchResults: Assembly {
	typealias View = AssetsSearchResultsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.business.instantiateViewController(withIdentifier: "AssetsSearchResultsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


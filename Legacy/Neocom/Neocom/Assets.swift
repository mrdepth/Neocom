//
//  Assets.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum Assets: Assembly {
	typealias View = AssetsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.business.instantiateViewController(withIdentifier: "AssetsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


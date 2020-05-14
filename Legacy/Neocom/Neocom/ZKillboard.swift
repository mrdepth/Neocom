//
//  ZKillboard.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/15/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum ZKillboard: Assembly {
	typealias View = ZKillboardViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.killReports.instantiateViewController(withIdentifier: "ZKillboardViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


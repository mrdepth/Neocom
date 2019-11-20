//
//  KillmailsPage.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum KillmailsPage: Assembly {
	typealias View = KillmailsPageViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		return _instantiate(input)
	}

	func instantiate() -> Future<View> {
		return _instantiate(nil)
	}

	private func _instantiate(_ input: View.Input?) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.killReports.instantiateViewController(withIdentifier: "KillmailsPageViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


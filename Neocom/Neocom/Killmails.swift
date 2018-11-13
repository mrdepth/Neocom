//
//  Killmails.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum Killmails: Assembly {
	typealias View = KillmailsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.killReports.instantiateViewController(withIdentifier: "KillmailsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


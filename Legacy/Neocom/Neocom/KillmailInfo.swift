//
//  KillmailInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/14/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum KillmailInfo: Assembly {
	typealias View = KillmailInfoViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.killReports.instantiateViewController(withIdentifier: "KillmailInfoViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


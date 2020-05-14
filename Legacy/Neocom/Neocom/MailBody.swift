//
//  MailBody.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MailBody: Assembly {
	typealias View = MailBodyViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.character.instantiateViewController(withIdentifier: "MailBodyViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


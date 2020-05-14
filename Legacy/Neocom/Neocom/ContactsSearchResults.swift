//
//  ContactsSearchResults.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum ContactsSearchResults: Assembly {
	typealias View = ContactsSearchResultsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.character.instantiateViewController(withIdentifier: "ContactsSearchResultsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


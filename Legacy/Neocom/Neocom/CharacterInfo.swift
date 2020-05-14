//
//  CharacterInfo.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/1/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum CharacterInfo: Assembly {
	typealias View = CharacterInfoViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.character.instantiateViewController(withIdentifier: "CharacterInfoViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


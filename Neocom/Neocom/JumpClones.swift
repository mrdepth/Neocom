//
//  JumpClones.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/1/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum JumpClones: Assembly {
	typealias View = JumpClonesViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.character.instantiateViewController(withIdentifier: "JumpClonesViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


//
//  MySkills.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MySkills: Assembly {
	typealias View = MySkillsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.character.instantiateViewController(withIdentifier: "MySkillsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


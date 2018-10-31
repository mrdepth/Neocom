//
//  MySkillsPage.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/31/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MySkillsPage: Assembly {
	typealias View = MySkillsPageViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.character.instantiateViewController(withIdentifier: "MySkillsPageViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


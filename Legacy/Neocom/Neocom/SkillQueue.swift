//
//  SkillQueue.swift
//  Neocom
//
//  Created by Artem Shimanski on 19/10/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum SkillQueue: Assembly {
	typealias View = SkillQueueViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.character.instantiateViewController(withIdentifier: "SkillQueueViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


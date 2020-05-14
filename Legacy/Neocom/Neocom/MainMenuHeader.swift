//
//  MainMenuHeader.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum MainMenuHeader: Assembly {
	case `default`
	case character
	case login
	
	func instantiate(_ input: Void) -> Future<MainMenuHeaderViewController> {
		let result: MainMenuHeaderViewController
		switch self {
		case .default:
			result = UIStoryboard.main.instantiateViewController(withIdentifier: "MainMenuHeaderViewController") as! MainMenuHeaderViewController
		case .character:
			result = UIStoryboard.main.instantiateViewController(withIdentifier: "MainMenuCharacterHeaderViewController") as! MainMenuHeaderViewController
		case .login:
			result = UIStoryboard.main.instantiateViewController(withIdentifier: "MainMenuLoginHeaderViewController") as! MainMenuHeaderViewController
		}
		return .init(result)
	}
	
}

//
//  API+Constants.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

extension ESI.Incursions.Incursion.State {
	var title: String {
		switch self {
		case .established:
			return NSLocalizedString("Established", comment: "")
		case .mobilizing:
			return NSLocalizedString("Mobilizing", comment: "")
		case .withdrawing:
			return NSLocalizedString("Withdrawing", comment: "")
		}
	}
	
}

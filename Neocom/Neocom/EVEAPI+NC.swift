//
//  EVEAPI+NC.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.05.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

extension ESI.Calendar.Summary.Response {
	var title: String {
		switch self {
		case .accepted:
			return NSLocalizedString("Accepted", comment: "")
		case .declined:
			return NSLocalizedString("Declined", comment: "")
		case .notResponded:
			return NSLocalizedString("Not Responded", comment: "")
		case .tentative:
			return NSLocalizedString("Tentative", comment: "")
		}
	}
}

extension ESI.Calendar.Response.Response {
	var title: String {
		switch self {
		case .accepted:
			return NSLocalizedString("Accepted", comment: "")
		case .declined:
			return NSLocalizedString("Declined", comment: "")
		case .tentative:
			return NSLocalizedString("Tentative", comment: "")
		}
	}
}

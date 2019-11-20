//
//  IndustryJobs.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/9/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

enum IndustryJobs: Assembly {
	typealias View = IndustryJobsViewController
	case `default`
	
	func instantiate(_ input: View.Input) -> Future<View> {
		switch self {
		case .default:
			let controller = UIStoryboard.business.instantiateViewController(withIdentifier: "IndustryJobsViewController") as! View
			controller.input = input
			return .init(controller)
		}
	}
}


//
//  NCLocationPickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCLocationPickerViewController: NCNavigationController {
	
	struct Mode: OptionSet {
		let rawValue: Int
		
		static let regions = Mode(rawValue: 1 << 0)
		static let solarSystems = Mode(rawValue: 1 << 1)
		static let all = [Mode.regions, Mode.solarSystems]
	}
	
	var mode: [Mode] = Mode.all
	
	var completionHandler: ((NCLocationPickerViewController, Any) -> Void)!
	
}

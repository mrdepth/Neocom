//
//  NCAdaptiveSegue.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit

class NCAdaptiveSegue: UIStoryboardSegue {
	override func perform() {
		if source.parent is UISearchController {
			source.presentingViewController?.navigationController?.pushViewController(destination, animated: true)
		}
		else {
			source.navigationController?.pushViewController(destination, animated: true)
		}
	}
}

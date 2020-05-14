//
//  NCLocationPickerContainerViewContrller.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCLocationPickerContainerViewContrller: NCPageViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		viewControllers = [
			storyboard!.instantiateViewController(withIdentifier: "NCRegionsViewController"),
			storyboard!.instantiateViewController(withIdentifier: "NCLocationPickerRecentViewContrller")
		]
	}
	
}

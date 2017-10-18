//
//  NCMarketPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 03.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCMarketPageViewController: NCPageViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		viewControllers = [
			storyboard!.instantiateViewController(withIdentifier: "NCMarketGroupsViewController"),
			storyboard!.instantiateViewController(withIdentifier: "NCMarketQuickbarViewController")
		]
	}
	
}

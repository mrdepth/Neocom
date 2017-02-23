//
//  NCFittingMenuViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingMenuViewController: NCPageViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		viewControllers = [storyboard!.instantiateViewController(withIdentifier: "NCFittingShipsViewController")]
	}
}

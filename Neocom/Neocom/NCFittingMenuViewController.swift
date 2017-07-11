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
		viewControllers = [storyboard!.instantiateViewController(withIdentifier: "NCFittingShipsViewController"),
		                   storyboard!.instantiateViewController(withIdentifier: "NCFittingStructuresViewController"),
		                   storyboard!.instantiateViewController(withIdentifier: "NCFittingFleetsViewController")]
		navigationItem.rightBarButtonItem = editButtonItem
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		for controller in viewControllers ?? [] {
			controller.setEditing(editing, animated: animated)
		}
	}
}

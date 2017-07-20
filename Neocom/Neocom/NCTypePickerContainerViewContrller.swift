//
//  NCTypePickerContainerViewContrller.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCTypePickerContainerViewContrller: NCPageViewController {
	var group: NCDBDgmppItemGroup? {
		didSet {
			if let name = group?.groupName {
				self.title = name
			}
		}
	}
	var predicate: NSPredicate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		if let predicate = predicate {
			let controller = storyboard!.instantiateViewController(withIdentifier: "NCTypePickerTypesViewController") as! NCTypePickerTypesViewController
			controller.predicate = predicate
			viewControllers = [
				controller,
				storyboard!.instantiateViewController(withIdentifier: "NCTypePickerRecentViewController"),
			]
		}
		else {
			let controller = storyboard!.instantiateViewController(withIdentifier: "NCTypePickerGroupsViewController") as! NCTypePickerGroupsViewController
			controller.parentGroup = group
			viewControllers = [
				controller,
				storyboard!.instantiateViewController(withIdentifier: "NCTypePickerRecentViewController"),
			]
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
	}
}

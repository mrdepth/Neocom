//
//  DgmTypePickerGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 16/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class DgmTypePickerGroupsViewController: TreeViewController<DgmTypePickerGroupsPresenter, SDEDgmppItemGroup>, TreeView, SearchableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		title = input?.groupName
	}
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		assert(input != nil)
		if let category = input?.category {
			return try! DgmTypePickerTypes.default.instantiate(.category(category)).get()
		}
		else {
			return try! DgmTypePickerTypes.default.instantiate(.group(input!)).get()
		}
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
	}
}

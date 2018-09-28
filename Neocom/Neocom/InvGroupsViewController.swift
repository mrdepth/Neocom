//
//  InvGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Expressible

class InvGroupsViewController: TreeViewController<InvGroupsPresenter, InvGroupsViewController.Input>, TreeView, SearchableViewController {
	enum Input {
		case category (SDEInvCategory)
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}

	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		switch input {
		case let .category(category)?:
			return try! InvTypes.default.instantiate(.category(category)).get()
		default:
			return try! InvTypes.default.instantiate(.none).get()
		}
	}

}


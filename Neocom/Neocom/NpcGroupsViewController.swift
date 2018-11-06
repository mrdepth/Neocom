//
//  NpcGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class NpcGroupsViewController: TreeViewController<NpcGroupsPresenter, NpcGroupsViewController.Input>, TreeView, SearchableViewController {
	enum Input {
		case root
		case parent(SDENpcGroup)
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		return try! InvTypes.default.instantiate(.npcGroup(nil)).get()
	}
	
}

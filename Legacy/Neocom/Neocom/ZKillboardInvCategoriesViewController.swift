//
//  ZKillboardInvCategoriesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class ZKillboardInvCategoriesViewController: TreeViewController<ZKillboardInvCategoriesPresenter, Void>, TreeView, SearchableViewController {
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}

	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		return try! ZKillboardInvTypes.default.instantiate(.none).get()
	}

}

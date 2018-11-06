//
//  WhTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class WhTypesViewController: TreeViewController<WhTypesPresenter, Void>, TreeView, SearchableViewController, UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		return try! WhTypes.default.instantiate().get()
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}

	
}

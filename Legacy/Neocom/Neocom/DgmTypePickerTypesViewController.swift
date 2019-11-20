//
//  DgmTypePickerTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 24/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

enum DgmTypePickerTypesViewControllerInput {
	case category(SDEDgmppItemCategory)
	case group(SDEDgmppItemGroup)
}

class DgmTypePickerTypesViewController: TreeViewController<DgmTypePickerTypesPresenter, DgmTypePickerTypesViewControllerInput>, TreeView, UISearchResultsUpdating, SearchableViewController {
	
	
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		guard let input = input else {return try! InvTypes.default.instantiate(.none).get()}
		return try! DgmTypePickerTypes.default.instantiate(input).get()
	}

	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
	}

}

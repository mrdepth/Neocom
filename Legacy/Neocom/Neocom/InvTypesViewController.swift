//
//  InvTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Expressible
import TreeController

enum InvTypesViewControllerInput {
	case none
	case group(SDEInvGroup)
	case category(SDEInvCategory)
	case marketGroup(SDEInvMarketGroup?)
	case npcGroup(SDENpcGroup?)
}

class InvTypesViewController: TreeViewController<InvTypesPresenter, InvTypesViewControllerInput>, TreeView, UISearchResultsUpdating, SearchableViewController {
	
	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		guard let input = input else {return try! InvTypes.default.instantiate(.none).get()}
		return try! InvTypes.default.instantiate(input).get()
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}

}



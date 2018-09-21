//
//  InvTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Expressible

class InvTypesViewController: TreeViewController<InvTypesPresenter, InvTypesViewController.Input>, TreeView, UISearchResultsUpdating, SearchableViewController {
	enum Input {
		case none
		case group(SDEInvGroup)
		case category(SDEInvCategory)
	}
	
	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		guard let input = input else {return try! InvTypes.default.instantiate(.none).get()}
		return try! InvTypes.default.instantiate(input).get()
	}

}



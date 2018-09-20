//
//  InvTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Expressible

class InvTypesViewController: TreeViewController<InvTypesPresenter, Predictable>, TreeView, UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}
}



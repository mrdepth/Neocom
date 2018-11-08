//
//  AssetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class AssetsViewController: TreeViewController<AssetsPresenter, Void>, TreeView, SearchableViewController {
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		return try! AssetsSearchResults.default.instantiate([]).get()
	}

}

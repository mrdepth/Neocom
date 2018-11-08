//
//  AssetsSearchResultsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/8/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class AssetsSearchResultsViewController: TreeViewController<AssetsSearchResultsPresenter, AssetsPresenter.Presentation>, TreeView, UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}
	
	
	func present(_ content: [Tree.Item.Section<Tree.Item.AssetRow>], animated: Bool) -> Future<Void> {
		return treeController.reloadData(content, options: [], with: .none)
	}
}

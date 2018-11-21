//
//  ZKillboardInvTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class ZKillboardInvTypesViewController: TreeViewController<ZKillboardInvTypesPresenter, ZKillboardInvTypesViewController.Input>, TreeView, UISearchResultsUpdating, SearchableViewController {
	
	enum Input {
		case group(SDEInvGroup)
		case category(SDEInvCategory)
		case none
	}
	
	override func treeController<T>(_ treeController: TreeController, configure cell: UITableViewCell, for item: T) where T : TreeItem {
		super.treeController(treeController, configure: cell, for: item)
		guard !(cell is TreeSectionCell) else {return}
		cell.accessoryType = .detailButton
	}
	
	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		guard let input = input else {return try! ZKillboardInvTypes.default.instantiate(.none).get()}
		return try! ZKillboardInvTypes.default.instantiate(input).get()
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}
	
//	override func treeController<T>(_ treeController: TreeController, accessoryButtonTappedFor item: T) where T : TreeItem {
//		super.treeController(treeController, accessoryButtonTappedFor: item)
//	}

}

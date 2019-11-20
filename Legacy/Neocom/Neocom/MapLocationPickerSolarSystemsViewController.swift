//
//  MapLocationPickerSolarSystemsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class MapLocationPickerSolarSystemsViewController: TreeViewController<MapLocationPickerSolarSystemsPresenter, SDEMapRegion>, TreeView, SearchableViewController {
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		guard let input = input else {return try! MapLocationPickerSearchResults.default.instantiate(.init(mode: .all, region: nil)).get()}
		return try! MapLocationPickerSearchResults.default.instantiate(.init(mode: .all, region: input)).get()
	}

	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEMapSolarSystem> else {return}
		presenter.didSelect(item.result)
	}
}


//
//  MapLocationPickerSearchResultsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

struct MapLocationPickerSearchResultsViewControllerInput {
	var mode: MapLocationPickerViewController.Mode
	var region: SDEMapRegion?
}

class MapLocationPickerSearchResultsViewController: TreeViewController<MapLocationPickerSearchResultsPresenter, MapLocationPickerSearchResultsViewControllerInput>, TreeView, UISearchResultsUpdating {
	
	func updateSearchResults(for searchController: UISearchController) {
		presenter.updateSearchResults(with: searchController.searchBar.text ?? "")
	}

	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		switch item {
		case let item as Tree.Item.MapSolarSystemSearchResultsRow:
			presenter.didSelect(item.solarSytem)
		case let item as Tree.Item.MapRegionSearchResultsRow:
			presenter.didSelect(item.region)
		case let item as Tree.Item.MapRegionBySolarSystemSearchResultsRow:
			guard let region = item.solarSytem.constellation?.region else {break}
			presenter.didSelect(region)
		default:
			break
		}
	}
}


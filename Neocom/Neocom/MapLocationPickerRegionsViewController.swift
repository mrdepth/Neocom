//
//  MapLocationPickerRegionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class MapLocationPickerRegionsViewController: TreeViewController<MapLocationPickerRegionsPresenter, MapLocationPickerViewController.Mode>, TreeView {
	
	override func treeController<T>(_ treeController: TreeController, configure cell: UITableViewCell, for item: T) where T : TreeItem {
		super.treeController(treeController, configure: cell, for: item)
		guard cell is TreeDefaultCell, input?.contains(.solarSystems) == true else {return}
		cell.accessoryType = input?.contains(.regions) == true ? .detailButton : .disclosureIndicator
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEMapRegion> else {return}
		if input?.contains(.solarSystems) == true {
			presenter.didOpen(item.result)
		}
		else {
			presenter.didSelect(item.result)
		}
	}
	
	override func treeController<T>(_ treeController: TreeController, accessoryButtonTappedFor item: T) where T : TreeItem {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEMapRegion> else {return}
		presenter.didSelect(item.result)
	}
}


//
//  MapLocationPickerRegionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class MapLocationPickerRegionsViewController: TreeViewController<MapLocationPickerRegionsPresenter, MapLocationPickerViewController.Mode>, TreeView, SearchableViewController {
	
	override func treeController<T>(_ treeController: TreeController, configure cell: UITableViewCell, for item: T) where T : TreeItem {
		super.treeController(treeController, configure: cell, for: item)
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEMapRegion> else {return}
		guard let cell = cell as? TreeDefaultCell, input?.contains(.solarSystems) == true else {return}
		if input?.contains(.regions) == true {
			let button = UIButton(type: .system)
			button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
			button.setTitle(NSLocalizedString("Select", comment: "").uppercased(), for: .normal)
			button.sizeToFit()

			cell.accessoryView = button
			cell.accessoryViewHandler = ActionHandler(button, for: .touchUpInside) { [weak self] _ in
				self?.presenter.didSelect(item.result)
			}
		}
		else {
			cell.accessoryType = .disclosureIndicator
		}
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
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
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		guard let input = input else {return try! MapLocationPickerSearchResults.default.instantiate(.init(mode: [.regions], region: nil)).get()}
		return try! MapLocationPickerSearchResults.default.instantiate(.init(mode: input, region: nil)).get()
	}

}


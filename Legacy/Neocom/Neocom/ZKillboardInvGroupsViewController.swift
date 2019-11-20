//
//  ZKillboardInvGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController

class ZKillboardInvGroupsViewController: TreeViewController<ZKillboardInvGroupsPresenter, SDEInvCategory>, TreeView, SearchableViewController {
	
	override func treeController<T>(_ treeController: TreeController, configure cell: UITableViewCell, for item: T) where T : TreeItem {
		super.treeController(treeController, configure: cell, for: item)
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEInvGroup>,
			let cell = cell as? TreeDefaultCell else {return}
		let button = UIButton(type: .system)
		button.setTitle(NSLocalizedString("Select", comment: "").uppercased(), for: .normal)
		button.sizeToFit()
		cell.accessoryView = button
		
		let group = item.result
		cell.accessoryViewHandler = ActionHandler(button, for: .touchUpInside) { [weak self] _ in
			self?.presenter.select(group)
		}
	}
	
	override func treeController<T>(_ treeController: TreeController, didSelectRowFor item: T) where T : TreeItem {
		super.treeController(treeController, didSelectRowFor: item)
		presenter.didSelect(item: item)
	}
	
	func searchResultsController() -> UIViewController & UISearchResultsUpdating {
		guard let input = input else {return try! ZKillboardInvTypes.default.instantiate(.none).get()}
		return try! ZKillboardInvTypes.default.instantiate(.category(input)).get()
	}
}

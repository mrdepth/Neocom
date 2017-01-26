//
//  NCFittingModulesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import Foundation

class NCFittingModuleRow: NCTreeRow {
	let type: NCDBInvType
	let module: NCFittingModule
	
	init(type: NCDBInvType, module: NCFittingModule) {
		self.type = type
		self.module = module
		super.init(cellIdentifier: "ModuleCell")
	}
	
	override func configure(cell: UITableViewCell) {
		
	}
}

class NCFittingModuleSection: NCTreeSection {
	let slot: NCFittingModuleSlot
	
	init(slot: NCFittingModuleSlot, children: [NCFittingModuleRow]) {
		self.slot = slot
		super.init(cellIdentifier: "HeaderCell", title: "Title", children: children)
	}
}


class NCFittingModulesViewController: UIViewController, NCTreeControllerDelegate {
	@IBOutlet weak var treeController: NCTreeController!
	@IBOutlet weak var tableView: UITableView!

	var engine: NCFittingEngine? {
		return (parent as? NCShipFittingViewController)?.engine
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.childrenKeyPath = "children"
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
	}
	
	//MARK: - NCTreeControllerDelegate
	
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return "Cell"
	}
}

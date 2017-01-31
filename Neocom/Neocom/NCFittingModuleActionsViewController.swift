//
//  NCFittingModuleActionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 31.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingModuleStateRow: TreeRow {
	let module: NCFittingModule
	let states: [NCFittingModuleState]
	
	init(module: NCFittingModule) {
		self.module = module
		
		let states: [NCFittingModuleState] = [.offline, .online, .active, .overloaded]
		self.states = states.filter {module.canHaveState($0)}
		
		super.init(cellIdentifier: "NCFittingModuleStateTableViewCell")
		
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCFittingModuleStateTableViewCell else {return}
		cell.segmentedControl?.removeAllSegments()
		cell.object = self
		var i = 0
		for state in states {
			cell.segmentedControl?.insertSegment(withTitle: state.title, at: i, animated: false)
			i += 1
		}
		
		module.engine?.perform {
			let state = self.module.state
			DispatchQueue.main.async {
				if let i = self.states.index(of: state) {
					cell.segmentedControl?.selectedSegmentIndex = i
				}
			}
		}
	}
}

class NCFittingModuleActionsViewController: UITableViewController, TreeControllerDelegate {
	var module: NCFittingModule?
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		navigationController?.preferredContentSize = CGSize(width: view.bounds.size.width, height: 320)

		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		treeController.rootNode = TreeNode()
		guard let module = self.module else {return}
		
		module.engine?.perform {
			var sections = [TreeNode]()
			if module.canHaveState(.online) {
				let section = DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "State", title: NSLocalizedString("State", comment: "").uppercased(), children: [NCFittingModuleStateRow(module: module)])
				sections.append(section)
			}
			
			DispatchQueue.main.async {
				self.treeController.rootNode?.children = sections
			}
		}
	}

	@IBAction func onDelete(_ sender: UIButton) {
		guard let module = self.module else {return}
		module.engine?.perform {
			guard let ship = module.owner as? NCFittingShip else {return}
			ship.removeModule(module)
		}
		self.dismiss(animated: true, completion: nil)
	}

	
	@IBAction func onChangeState(_ sender: UISegmentedControl) {
		guard let cell = sender.ancestor(of: NCFittingModuleStateTableViewCell.self) else {return}
		guard let node = cell.object as? NCFittingModuleStateRow else {return}
		let state = node.states[sender.selectedSegmentIndex]
		module?.engine?.perform {
			self.module?.preferredState = state
		}
	}
}

//
//  NCFittingTargetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit


class NCFittingTargetsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	var modules: [NCFittingModule]?
	var completionHandler: ((NCFittingTargetsViewController, NCFittingShip?) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCFleetMemberTableViewCell.default])

		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		guard let module = modules?.first else {return}
		guard let ship = module.owner as? NCFittingShip else {return}
		guard let character = ship.owner as? NCFittingCharacter else {return}
		guard let gang = character.owner as? NCFittingGang else {return}
		
		module.engine?.perform {
			let targets = gang.pilots.flatMap {return $0 == character ? nil : $0}
			let currentTarget = module.target?.owner as? NCFittingCharacter
			var rows: [TreeNode] = targets.map {NCFleetMemberRow(pilot: $0)}
			
			let i = currentTarget != nil ? targets.index(of: currentTarget!) : nil
			
			DispatchQueue.main.async {
				let root = TreeNode()
				root.children = rows
				self.treeController.content = root
				if let i = i {
					let row = rows[i]
					self.treeController.selectCell(for: row, animated: false, scrollPosition: .bottom)
				}
			}
		}
	}
	
	@IBAction func clearTarget(_ sender: Any) {
		completionHandler(self, nil)
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let node = node as? NCFleetMemberRow {
			node.pilot.engine?.performBlockAndWait {
				self.completionHandler(self, node.pilot.ship)
			}
		}
	}
}

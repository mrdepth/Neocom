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

class NCFittingModuleInfoRow: TreeRow {
	let module: NCFittingModule
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.module.typeID]
	}()
	
	init(module: NCFittingModule) {
		self.module = module
		super.init(cellIdentifier: "Cell", segue: "NCDatabaseTypeInfoViewController")
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.object = type
	}

}

class NCFittingChargeRow: NCChargeRow {
	let charges: Int
	let module: NCFittingModule?
	lazy var chargeCategory: NCDBDgmppItemCategory? = {
		guard let module = self.module else {return nil}
		return NCDatabase.sharedDatabase?.invTypes[module.typeID]?.dgmppItem?.charge
	}()
	init(charge: NCFittingCharge) {
		module = charge.owner as? NCFittingModule
		charges = (charge.owner as? NCFittingModule)?.charges ?? 0
		super.init(typeID: charge.typeID, segue: "NCFittingAmmoViewController", accessoryButtonSegue: "NCDatabaseTypeInfoViewController")
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCChargeTableViewCell else {return}
		cell.object = chargeCategory
		if charges > 0 {
			cell.titleLabel?.attributedText = (type?.typeName ?? "") + " x\(charges)" * [NSForegroundColorAttributeName: UIColor.caption]
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

		guard let module = self.module else {return}
		
		var sections = [TreeNode]()
		module.engine?.performBlockAndWait {
			
			sections.append(NCFittingModuleInfoRow(module: module))
			
			if module.canHaveState(.online) {
				let section = DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "State", title: NSLocalizedString("State", comment: "").uppercased(), children: [NCFittingModuleStateRow(module: module)])
				sections.append(section)
			}
			if let charge = module.charge {
				let section = DefaultTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Charge", title: NSLocalizedString("Charge", comment: "").uppercased(), children: [NCFittingChargeRow(charge: charge)])
				sections.append(section)
			}
			
		}
		let root = TreeNode()
		root.children = sections
		treeController.rootNode = root
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
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let segue = node.segue else {return}
		performSegue(withIdentifier: segue, sender: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let node = node as? TreeRow else {return}
		guard let segue = node.segue else {return}
		performSegue(withIdentifier: segue, sender: treeController.cell(for: node))
	}
	
	//MARK: - Navigation
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		switch segue.identifier {
		case "NCDatabaseTypeInfoViewController"?:
			guard let controller = segue.destination as? NCDatabaseTypeInfoViewController,
				let cell = sender as? NCTableViewCell,
				let type = cell.object as? NCDBInvType else {
					return
			}
			controller.type = type
		case "NCFittingAmmoViewController"?:
			guard let controller = segue.destination as? NCFittingAmmoViewController,
				let cell = sender as? NCTableViewCell,
				let category = cell.object as? NCDBDgmppItemCategory else {
					return
			}
			controller.category = category
		default:
			break
		}
	}
}

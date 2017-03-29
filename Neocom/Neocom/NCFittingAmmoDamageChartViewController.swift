//
//  NCFittingAmmoDamageChartViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.03.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

fileprivate let Limit = 5

class NCFittingAmmoDamageChartViewController: UIViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	@IBOutlet weak var tableView: UITableView!
	@IBOutlet weak var stepper: UIStepper!
	@IBOutlet weak var chargesStackView: UIStackView!
	@IBOutlet weak var damageChartView: NCFittingAmmoDamageChartView!

	
	var category: NCDBDgmppItemCategory?
	var modules: [NCFittingModule]?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		tableView.register([Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default])

		guard let category = category else {return}
		guard let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) else {return}
		title = group.groupName
		
		guard let ammo = NCAmmoSection(category: category) else {return}
		guard let modules = modules else {return}
		guard let module = modules.first else {return}
		
		let root = TreeNode()
		root.children = [ammo]
		
		treeController.content = root

	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}
		guard let damageChartRow = treeController.content?.children.first as? NCFittingAmmoDamageChartRow else {return}
		
		if damageChartRow.charges.count >= Limit {
			treeController.deselectCell(for: node, animated: true)
		}
		else {
			let typeID = Int(node.object.typeID)
			damageChartRow.charges.append(typeID)
			
			guard let cell = treeController.cell(for: damageChartRow) as? NCFittingAmmoDamageChartTableViewCell else {return}
			damageChartRow.configure(cell: cell)
			tableView.reloadRows(at: [], with: .fade)
		}
	}
	
	func treeController(_ treeController: TreeController, didDeselectCellWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}
		guard let damageChartRow = treeController.content?.children.first as? NCFittingAmmoDamageChartRow else {return}
		let typeID = Int(node.object.typeID)
		if let i = damageChartRow.charges.index(of: typeID) {
			damageChartRow.charges.remove(at: i)
		}
		
		guard let cell = treeController.cell(for: damageChartRow) as? NCFittingAmmoDamageChartTableViewCell else {return}
		damageChartRow.configure(cell: cell)
		tableView.reloadRows(at: [], with: .fade)
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
		default:
			break
		}
	}
}

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
	
	lazy var hullType: NCDBDgmppHullType? = {
		guard let module = self.modules?.first else {return nil}
		var hullType: NCDBDgmppHullType?
		module.engine?.performBlockAndWait {
			guard let ship = module.owner as? NCFittingShip else {return}
			hullType = NCDatabase.sharedDatabase?.invTypes[ship.typeID]?.hullType
		}
		return hullType
	}()
	
	var charges: [Int] = []

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
		
		damageChartView.targetSignature = Double(hullType?.signature ?? 0)
		damageChartView.module = module
		damageChartView.xAxis = Axis(range: 0...0, formatter: NCUnitFormatter(unit: .meter, style: .short))
		damageChartView.yAxis = Axis(range: 0...0, formatter: NCUnitFormatter(unit: .none, style: .short))
		
		damageChartView.updateHandler = { [weak damageChartView] updates in
			let dps = updates.map ({$0.value.dps}).max() ?? 0
			let range = updates.map ({$0.value.range}).max() ?? 0
			damageChartView?.xAxis = Axis(range: 0...range, formatter: NCUnitFormatter(unit: .meter, style: .short))
			damageChartView?.yAxis = Axis(range: 0...dps, formatter: NCUnitFormatter(unit: .none, style: .short))
		}
		
		let root = TreeNode()
		root.children = [ammo]
		
		treeController.content = root

	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}
		
		if charges.count >= Limit {
			treeController.deselectCell(for: node, animated: true)
		}
		else {
			let typeID = Int(node.object.typeID)
			charges.append(typeID)
			damageChartView.charges = charges
			tableView.reloadRows(at: [], with: .fade)
		}
	}
	
	func treeController(_ treeController: TreeController, didDeselectCellWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}

		let typeID = Int(node.object.typeID)
		if let i = charges.index(of: typeID) {
			charges.remove(at: i)
		}
		
		damageChartView.charges = charges
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

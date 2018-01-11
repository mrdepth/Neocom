//
//  NCFittingAmmoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import Dgmpp

class NCAmmoNode: NCFetchedResultsObjectNode<NCDBInvType> {
	
	required init(object: NCDBInvType) {
		super.init(object: object)
		
		self.cellIdentifier = object.dgmppItem?.damage == nil ? Prototype.NCDefaultTableViewCell.compact.reuseIdentifier : Prototype.NCChargeTableViewCell.default.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		if let cell = cell as? NCChargeTableViewCell {
			cell.titleLabel?.text = object.typeName
			cell.iconView?.image = object.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.object = object
			if let damage = object.dgmppItem?.damage {
				var total = damage.emAmount + damage.kineticAmount + damage.thermalAmount + damage.explosiveAmount
				if total == 0 {
					total = 1
				}
				
				cell.emLabel.progress = damage.emAmount / total
				cell.emLabel.text = NCUnitFormatter.localizedString(from: damage.emAmount, unit: .none, style: .short)
				
				cell.kineticLabel.progress = damage.kineticAmount / total
				cell.kineticLabel.text = NCUnitFormatter.localizedString(from: damage.kineticAmount, unit: .none, style: .short)
				
				cell.thermalLabel.progress = damage.thermalAmount / total
				cell.thermalLabel.text = NCUnitFormatter.localizedString(from: damage.thermalAmount, unit: .none, style: .short)
				
				cell.explosiveLabel.progress = damage.explosiveAmount / total
				cell.explosiveLabel.text = NCUnitFormatter.localizedString(from: damage.explosiveAmount, unit: .none, style: .short)
				
			}
			else {
				for label in [cell.emLabel, cell.kineticLabel, cell.thermalLabel, cell.explosiveLabel] {
					label?.progress = 0
					label?.text = "0"
				}
			}
		}
		else if let cell = cell as? NCDefaultTableViewCell {
			cell.titleLabel?.text = object.typeName
			cell.iconView?.image = object.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
			cell.object = object
			cell.accessoryType = .detailButton
		}
	}
}

class NCAmmoSection: FetchedResultsNode<NCDBInvType> {
	init?(category: NCDBDgmppItemCategory, objectNode: NCFetchedResultsObjectNode<NCDBInvType>.Type) {
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return nil}
		guard let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) else {return nil}
	
		let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
		request.predicate = NSPredicate(format: "dgmppItem.groups CONTAINS %@", group)
		request.sortDescriptors = [
			NSSortDescriptor(key: "metaGroup.metaGroupID", ascending: true),
			NSSortDescriptor(key: "metaLevel", ascending: true),
			NSSortDescriptor(key: "typeName", ascending: true)]
		
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "metaGroup.metaGroupID", cacheName: nil)
		
		super.init(resultsController: controller, sectionNode: NCMetaGroupFetchedResultsSectionNode<NCDBInvType>.self, objectNode: objectNode)
	}
}

class NCFittingAmmoViewController: NCTreeViewController {

	var category: NCDBDgmppItemCategory?
	var completionHandler: ((NCFittingAmmoViewController, NCDBInvType?) -> Void)!
	var modules: [DGMModule]?

	
	override func viewDidLoad() {
		super.viewDidLoad()
		let module = modules?.first
		if module?.charge == nil {
			self.navigationItem.rightBarButtonItem = nil
		}

		tableView.register([Prototype.NCActionTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default])
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		defer {completionHandler()}
		
		guard let category = category else {return}
		guard let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) else {return}
		title = group.groupName
		
		guard let ammo = NCAmmoSection(category: category, objectNode: NCAmmoNode.self) else {return}
		
		let root = TreeNode()
		
		try? ammo.resultsController.performFetch()
		let dealsDamage = ammo.resultsController.fetchedObjects?.first?.dgmppItem?.damage != nil
		
		if dealsDamage {
			let route = Router.Fitting.AmmoDamageChart(category: category, modules: modules ?? [])
			root.children = [NCActionRow(title: NSLocalizedString("Compare", comment: ""), route: route), ammo]
		}
		else {
			root.children = [ammo]
		}
		
		treeController?.content = root
		
	}
	
	@IBAction func onClear(_ sender: Any) {
		completionHandler(self, nil)
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		
		if let node = node as? NCAmmoNode {
			completionHandler(self, node.object)
		}
	}
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		guard let node = node as? NCAmmoNode else {return}
		Router.Database.TypeInfo(node.object).perform(source: self, sender: treeController.cell(for: node))
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

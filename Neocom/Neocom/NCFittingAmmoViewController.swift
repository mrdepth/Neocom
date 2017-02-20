//
//  NCFittingAmmoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCAmmoNode: FetchedResultsObjectNode<NCDBInvType> {
	
	required init(object: NCDBInvType) {
		super.init(object: object)
		self.cellIdentifier = object.dgmppItem?.damage == nil ? "NCDefaultTableViewCell" : "NCChargeTableViewCell"
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
		}
	}
}

class NCFittingAmmoViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	var category: NCDBDgmppItemCategory?
	var completionHandler: ((NCFittingAmmoViewController, NCDBInvType) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self

		guard let category = category else {return}
		guard let group: NCDBDgmppItemGroup = NCDatabase.sharedDatabase?.viewContext.fetch("DgmppItemGroup", where: "category == %@ AND parentGroup == NULL", category) else {return}
		title = group.groupName
		
		let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
		request.predicate = NSPredicate(format: "dgmppItem.groups CONTAINS %@", group)
		request.sortDescriptors = [
			NSSortDescriptor(key: "metaGroup.metaGroupID", ascending: true),
			NSSortDescriptor(key: "metaLevel", ascending: true),
			NSSortDescriptor(key: "typeName", ascending: true)]

		
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return}
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "metaGroup.metaGroupID", cacheName: nil)
		
		let root = FetchedResultsNode(resultsController: controller, sectionNode: NCMetaGroupFetchedResultsSectionNode<NCDBInvType>.self, objectNode: NCAmmoNode.self)
		treeController.rootNode = root
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}
		completionHandler(self, node.object)
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let node = node as? NCAmmoNode else {return}
		Router.Database.TypeInfo(node.object).perform(source: self, view: treeController.cell(for: node))
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

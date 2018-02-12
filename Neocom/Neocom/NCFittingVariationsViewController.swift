//
//  NCFittingVariationsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCFittingVariationRow: NCDatabaseTypeRow<NCDBInvType> {
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.accessoryType = .detailButton
	}
}

class NCFittingVariationsViewController: NCTreeViewController {

	var type: NCDBInvType?
	var completionHandler: ((NCFittingVariationsViewController, NCDBInvType) -> Void)!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCModuleTableViewCell.default,
		                    Prototype.NCShipTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default,
		                    ])

	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		
		guard let type = type else {return}
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return}

		let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
		let what = type.parentType ?? type
		request.predicate = NSPredicate(format: "(parentType == %@ OR self == %@) && dgmppItem <> nil", what, what)
		request.sortDescriptors = [
			NSSortDescriptor(key: "metaGroup.metaGroupID", ascending: true),
			NSSortDescriptor(key: "metaLevel", ascending: true),
			NSSortDescriptor(key: "typeName", ascending: true)]
		
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "metaGroup.metaGroupID", cacheName: nil)
		
		let root = FetchedResultsNode(resultsController: controller, sectionNode: NCMetaGroupFetchedResultsSectionNode<NCDBInvType>.self, objectNode: NCFittingVariationRow.self)
		treeController?.content = root
		completionHandler()
	}

	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let node = node as? NCFittingVariationRow else {return}
		completionHandler(self, node.object)
	}
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		guard let node = node as? NCFittingVariationRow else {return}
		Router.Database.TypeInfo(node.object).perform(source: self, sender: treeController.cell(for: node))
	}
	
}

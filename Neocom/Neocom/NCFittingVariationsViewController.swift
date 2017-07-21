//
//  NCFittingVariationsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 06.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCDBVariationRow: NCDatabaseTypeRow<NCDBInvType> {
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.accessoryType = .detailButton
	}
}

class NCFittingVariationsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
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

		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
		
		guard let type = type else {return}
		
		let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
		let what = type.parentType ?? type
		request.predicate = NSPredicate(format: "parentType == %@ OR self == %@", what, what)
		request.sortDescriptors = [
			NSSortDescriptor(key: "metaGroup.metaGroupID", ascending: true),
			NSSortDescriptor(key: "metaLevel", ascending: true),
			NSSortDescriptor(key: "typeName", ascending: true)]
		
		
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return}
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "metaGroup.metaGroupID", cacheName: nil)
		
		let root = FetchedResultsNode(resultsController: controller, sectionNode: NCMetaGroupFetchedResultsSectionNode<NCDBInvType>.self, objectNode: NCDBVariationRow.self)
		treeController.content = root
	}

	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let node = node as? NCDBVariationRow else {return}
		completionHandler(self, node.object)
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let node = node as? NCDBVariationRow else {return}
		Router.Database.TypeInfo(node.object).perform(source: self, view: treeController.cell(for: node))
	}
	
}

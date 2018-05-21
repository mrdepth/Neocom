//
//  NCDatabaseTypeVariationsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

class NCDatabaseTypeVariationsViewController: NCTreeViewController {
	
	var type: NCDBInvType?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCModuleTableViewCell.default,
		                    Prototype.NCShipTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default,
		                    ])
		
	}
	
	override func content() -> Future<TreeNode?> {
		guard let type = type else {return .init(nil)}
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return .init(nil)}
		
		let request = NSFetchRequest<NCDBInvType>(entityName: "InvType")
		let what = type.parentType ?? type
		request.predicate = NSPredicate(format: "parentType == %@ OR self == %@", what, what)
		request.sortDescriptors = [
			NSSortDescriptor(key: "metaGroup.metaGroupID", ascending: true),
			NSSortDescriptor(key: "metaLevel", ascending: true),
			NSSortDescriptor(key: "typeName", ascending: true)]
		
		
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "metaGroup.metaGroupID", cacheName: nil)
		
		return .init(FetchedResultsNode(resultsController: controller, sectionNode: NCMetaGroupFetchedResultsSectionNode<NCDBInvType>.self, objectNode: NCDatabaseTypeRow<NCDBInvType>.self))
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let node = node as? NCDatabaseTypeRow<NCDBInvType> else {return}
		Router.Database.TypeInfo(node.object).perform(source: self, sender: treeController.cell(for: node))
	}
	
}

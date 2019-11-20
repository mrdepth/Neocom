//
//  NCDatabaseCertificateGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

class NCDatabaseCertificateGroupsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCDefaultTableViewCell.compact])

	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController?.content = nil
		}
	}
	
	override func content() -> Future<TreeNode?> {
		let request = NSFetchRequest<NCDBInvGroup>(entityName: "InvGroup")
		request.predicate = NSPredicate(format: "certificates.@count > 0")
		request.sortDescriptors = [NSSortDescriptor(key: "groupName", ascending: true)]
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
		
		return .init(FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCDatabaseGroupRow.self))
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCDatabaseGroupRow else {return}
		Router.Database.Certificates(group: row.object).perform(source: self, sender: treeController.cell(for: node))
	}
	
}

//
//  NCFittingFleetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData


class NCFittingFleetsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCDefaultTableViewCell.default])
		
		treeController.delegate = self
		
		guard let context = NCStorage.sharedStorage?.viewContext else {return}
		
		let request = NSFetchRequest<NCFleet>(entityName: "Fleet")
		request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
		let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
		
		let root = FetchedResultsNode(resultsController: controller, objectNode: NCFleetRow.self)
		treeController.content = root
		
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		
		if let node = node as? NCFleetRow {
			NCStorage.sharedStorage?.performBackgroundTask({ (managedObjectContext) in
				guard let fleet = (try? managedObjectContext.existingObject(with: node.object.objectID)) as? NCFleet else {return}
				let engine = NCFittingEngine()
				engine.performBlockAndWait {
					let fleet = NCFittingFleet(fleet: fleet, engine: engine)
					DispatchQueue.main.async {
						Router.Fitting.Editor(fleet: fleet, engine: engine).perform(source: self)
					}
				}
			})
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCFleetRow else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { _ in
			guard let context = NCStorage.sharedStorage?.viewContext else {return}
			let fleet = node.object
			context.delete(fleet)
			if context.hasChanges {
				try? context.save()
			}
		}
		
		return [deleteAction]
	}
	
	func treeControllerDidUpdateContent(_ treeController: TreeController) {
		tableView.backgroundView = (treeController.content?.children.count ?? 0) > 0 ? nil : NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: ""))
	}
	
}

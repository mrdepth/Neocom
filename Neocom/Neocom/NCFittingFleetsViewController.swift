//
//  NCFittingFleetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData


class NCFittingFleetsViewController: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.default])
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func setEditing(_ editing: Bool, animated: Bool) {
		super.setEditing(editing, animated: animated)
		updateToolbar()
	}
	
	@IBAction func onDelete(_ sender: UIBarButtonItem) {
		guard let selected = treeController?.selectedNodes().flatMap ({($0 as? NCFleetRow)?.object}) else {return}
		guard !selected.isEmpty else {return}
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		controller.addAction(UIAlertAction(title: String(format: NSLocalizedString("Delete %d Fleets", comment: ""), selected.count), style: .destructive) { [weak self] _ in
			selected.forEach { object in
				object.managedObjectContext?.delete(object)
			}
			if let context = selected.first?.managedObjectContext, context.hasChanges {
				try? context.save()
			}
			self?.updateToolbar()
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		present(controller, animated: true, completion: nil)
		controller.popoverPresentationController?.barButtonItem = sender
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		updateToolbar()
	}
	
	override func treeController(_ treeController: TreeController, didDeselectCellWithNode node: TreeNode) {
		super.treeController(treeController, didDeselectCellWithNode: node)
		updateToolbar()
	}
	
	func treeController(_ treeController: TreeController, didCollapseCellWithNode node: TreeNode) {
		updateToolbar()
	}
	
	func treeControllerDidUpdateContent(_ treeController: TreeController) {
		updateToolbar()
		tableView.backgroundView = (treeController.content?.children.count ?? 0) > 0 ? nil : NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: ""))
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCFleetRow else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { _,_  in
			guard let context = NCStorage.sharedStorage?.viewContext else {return}
			let fleet = node.object
			context.delete(fleet)
			if context.hasChanges {
				try? context.save()
			}
		}
		
		return [deleteAction]
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		
		if let context = NCStorage.sharedStorage?.viewContext {
			let request = NSFetchRequest<NCFleet>(entityName: "Fleet")
			request.sortDescriptors = [NSSortDescriptor(key: "name", ascending: true)]
			let controller = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: nil, cacheName: nil)
			
			let root = FetchedResultsNode(resultsController: controller, objectNode: NCFleetRow.self)
			treeController?.content = root
			tableView.backgroundView = !root.children.isEmpty ? nil : NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: ""))
		}
		
		completionHandler()
	}

	
	private func updateToolbar() {
		toolbarItems?.last?.isEnabled = treeController?.selectedNodes().isEmpty == false
	}

}

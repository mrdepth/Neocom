//
//  NCFittingFleetsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.02.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit

class NCFittingFleetsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.delegate = self
	}
	
	override func didReceiveMemoryWarning() {
		super.didReceiveMemoryWarning()
		// Dispose of any resources that can be recreated.
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		
		if treeController.rootNode == nil {
			self.treeController.rootNode = TreeNode()
			reload()
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		
		if let node = node as? NCLoadoutRow {
			NCStorage.sharedStorage?.performBackgroundTask({ (managedObjectContext) in
				guard let loadout = (try? managedObjectContext.existingObject(with: node.loadoutID)) as? NCLoadout else {return}
				let engine = NCFittingEngine()
				engine.performBlockAndWait {
					let fleet = NCFittingFleet(loadouts: [loadout], engine: engine)
					DispatchQueue.main.async {
						Router.Fitting.Editor(fleet: fleet, engine: engine).perform(source: self)
					}
				}
			})
		}
		else if let route = (node as? TreeRow)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
		}
	}
	
	func treeController(_ treeController: TreeController, editActionsForNode node: TreeNode) -> [UITableViewRowAction]? {
		guard let node = node as? NCLoadoutRow else {return nil}
		
		let deleteAction = UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: "")) { _ in
			guard let context = NCStorage.sharedStorage?.viewContext else {return}
			guard let loadout = (try? context.existingObject(with: node.loadoutID)) as? NCLoadout else {return}
			context.delete(loadout)
			if context.hasChanges {
				try? context.save()
			}
		}
		
		return [deleteAction]
	}
	
	//MARK: - Private
	
	private func reload() {
		var sections = [TreeNode]()
		
		
		sections.append(NCActionRow(cellIdentifier: "NCDefaultTableViewCell", image: #imageLiteral(resourceName: "fitting"), title: NSLocalizedString("New Ship Fit", comment: ""), accessoryType: .disclosureIndicator, route: Router.Database.TypePicker(category: NCDBDgmppItemCategory.category(categoryID: .ship)!, completionHandler: {[weak self] (controller, type) in
			guard let strongSelf = self else {return}
			strongSelf.dismiss(animated: true)
			
			let engine = NCFittingEngine()
			let typeID = Int(type.typeID)
			engine.perform {
				let fleet = NCFittingFleet(typeID: typeID, engine: engine)
				DispatchQueue.main.async {
					Router.Fitting.Editor(fleet: fleet, engine: engine).perform(source: strongSelf)
				}
			}
			
		})))
		
		sections.append(NCActionRow(cellIdentifier: "NCDefaultTableViewCell", image: #imageLiteral(resourceName: "browser"), title: NSLocalizedString("Import/Export", comment: ""), accessoryType: .disclosureIndicator))
		sections.append(NCActionRow(cellIdentifier: "NCDefaultTableViewCell", image: #imageLiteral(resourceName: "eveOnlineLogin"), title: NSLocalizedString("Browse Ingame Fits", comment: ""), accessoryType: .disclosureIndicator))
		
		sections.append(NCLoadoutsSection(categoryID: .ship))
		self.treeController.rootNode?.children = sections
	}
}

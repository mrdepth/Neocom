//
//  NCNPCPickerTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCNPCPickerTypesViewController: NCTreeViewController, NCSearchableViewController {
	
	private let gate = NCGate()
	var predicate: NSPredicate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact,
		                    Prototype.NCModuleTableViewCell.default,
		                    Prototype.NCShipTableViewCell.default,
		                    Prototype.NCChargeTableViewCell.default,
		                    ])
		
		if navigationController != nil {
			setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCZKillboardTypesViewController"))
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController?.content == nil {
			reloadData()
		}
	}
	
	func reloadData() {
		gate.perform {
			NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
				let section = NCDatabaseTypesSection(managedObjectContext: managedObjectContext, predicate: self.predicate, sectionNode: NCDefaultFetchedResultsSectionNode<NSDictionary>.self, objectNode: NCDatabaseTypePickerRow.self)
				try? section.resultsController.performFetch()
				
				DispatchQueue.main.async {
					self.treeController?.content = section
					self.tableView.backgroundView = (section.resultsController.fetchedObjects?.count ?? 0) == 0 ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				}
			})
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController?.content = nil
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCDatabaseTypePickerRow else {return}
		guard let typeID = row.object["typeID"] as? Int else {return}
		guard let type = NCDatabase.sharedDatabase?.invTypes[typeID] else {return}
		guard let picker = (navigationController as? NCNPCPickerViewController) ?? presentingViewController?.navigationController as? NCNPCPickerViewController else {return}
		picker.completionHandler(picker, type)
	}
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		guard let row = node as? NCDatabaseTypePickerRow else {return}
		guard let typeID = row.object["typeID"] as? Int else {return}
		Router.Database.TypeInfo(typeID).perform(source: self, sender: treeController.cell(for: node))
	}
	
	//MARK: NCSearchableViewController
	
	var searchController: UISearchController?
	
	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCDatabaseTypesViewController else {return}
		if let text = searchController.searchBar.text, let other = self.predicate, text.characters.count > 2 {
			predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [other, NSPredicate(format: "typeName CONTAINS[C] %@", text)])
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
}

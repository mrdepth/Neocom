//
//  NCTypePickerTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCDatabaseTypePickerRow: NCDatabaseTypeRow<NSDictionary> {
	required init(object: NSDictionary) {
		super.init(object: object)
		if let typeID = object["typeID"] as? Int {
			accessoryButtonRoute = Router.Database.TypeInfo(typeID)
		}
	}
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.accessoryType = .detailButton
	}
}

class NCTypePickerTypesViewController: NCTreeViewController, NCSearchableViewController {
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
			setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCTypePickerTypesViewController"))
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
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCDatabaseTypeInfoViewController" {
			let controller = segue.destination as? NCDatabaseTypeInfoViewController
			let object = (sender as! NCDefaultTableViewCell).object as! NSDictionary
			controller?.type = NCDatabase.sharedDatabase?.invTypes[object["typeID"] as! Int]
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)

		guard let typePickerController =  (presentingViewController?.navigationController as? NCTypePickerViewController) ??
			navigationController as? NCTypePickerViewController else {return}
		guard let row = node as? NCDatabaseTypePickerRow else {return}
		guard let typeID = row.object["typeID"] as? Int else {return}
		guard let type = NCDatabase.sharedDatabase?.invTypes[typeID] else {return}
		guard let context = NCCache.sharedCache?.viewContext else {return}

		guard let category = typePickerController.category else {return}
		var recent: NCCacheTypePickerRecent? = context.fetch("TypePickerRecent", where: "category == %d AND subcategory == %d AND raceID == %d AND typeID == %d", category.category, category.subcategory, category.race?.raceID ?? 0, type.typeID)
		if recent == nil {
			recent = NCCacheTypePickerRecent(entity: NSEntityDescription.entity(forEntityName: "TypePickerRecent", in: context)!, insertInto: context)
			recent?.category = category.category
			recent?.subcategory = category.subcategory
			recent?.raceID = category.race?.raceID ?? 0
			recent?.typeID = type.typeID
		}
		recent?.date = Date() as NSDate
		if context.hasChanges {
			try? context.save()
		}
		typePickerController.completionHandler(typePickerController, type)
	}

	
	//MARK: UISearchResultsUpdating
	
	var searchController: UISearchController?

	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCTypePickerTypesViewController else {return}
		if let text = searchController.searchBar.text, let other = self.predicate, text.characters.count > 0 {
			predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [other, NSPredicate(format: "typeName CONTAINS[C] %@", text)])
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
}

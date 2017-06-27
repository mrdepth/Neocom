//
//  NCZKillboardTypesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCZKillboardTypeRow: NCDatabaseTypeRow {
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		cell.accessoryType = .detailButton
	}
}


class NCZKillboardTypesViewController: UITableViewController, UISearchResultsUpdating, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	
	private var searchController: UISearchController?
	private let gate = NCGate()
	var predicate: NSPredicate?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])
		treeController.delegate = self
		
		
		if navigationController != nil {
			setupSearchController()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController.content == nil {
			reloadData()
		}
	}
	
	func reloadData() {
		gate.perform {
			NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
				let request = NSFetchRequest<NSDictionary>(entityName: "InvType")
				request.predicate = self.predicate ?? NSPredicate(value: false)
				request.sortDescriptors = [
					NSSortDescriptor(key: "metaGroup.metaGroupID", ascending: true),
					NSSortDescriptor(key: "metaLevel", ascending: true),
					NSSortDescriptor(key: "typeName", ascending: true)]
				
				let entity = managedObjectContext.persistentStoreCoordinator!.managedObjectModel.entitiesByName[request.entityName!]!
				let propertiesByName = entity.propertiesByName
				var properties = [NSPropertyDescription]()
				properties.append(propertiesByName["typeID"]!)
				properties.append(propertiesByName["typeName"]!)
				properties.append(propertiesByName["metaLevel"]!)
				properties.append(NSExpressionDescription(name: "metaGroupID", resultType: .integer32AttributeType, expression: NSExpression(forKeyPath: "metaGroup.metaGroupID")))
				properties.append(NSExpressionDescription(name: "icon", resultType: .objectIDAttributeType, expression: NSExpression(forKeyPath: "icon")))
				properties.append(NSExpressionDescription(name: "metaGroupName", resultType: .stringAttributeType, expression: NSExpression(forKeyPath: "metaGroup.metaGroupName")))
				request.propertiesToFetch = properties
				request.resultType = .dictionaryResultType
				
				let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: "metaGroupName", cacheName: nil)
				try? results.performFetch()
				
				DispatchQueue.main.async {
					self.treeController.content = FetchedResultsNode(resultsController: results, sectionNode: NCDefaultFetchedResultsSectionNode<NSDictionary>.self, objectNode: NCZKillboardTypeRow.self)
					
					self.tableView.backgroundView = (results.fetchedObjects?.count ?? 0) == 0 ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				}
			})
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController.content = nil
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let row = node as? NCDatabaseTypeRow else {return}
		guard let typeID = row.object["typeID"] as? Int else {return}
		guard let type = NCDatabase.sharedDatabase?.invTypes[typeID] else {return}
		guard let picker = (navigationController as? NCZKillboardTypePickerViewController) ?? presentingViewController?.navigationController as? NCZKillboardTypePickerViewController else {return}
		picker.completionHandler(picker, type)
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let row = node as? NCDatabaseTypeRow else {return}
		guard let typeID = row.object["typeID"] as? Int else {return}
		Router.Database.TypeInfo(typeID).perform(source: self, view: treeController.cell(for: node))
	}
	
	//MARK: UISearchResultsUpdating
	
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
	
	//MARK: Private
	
	private func setupSearchController() {
		searchController = UISearchController(searchResultsController: self.storyboard?.instantiateViewController(withIdentifier: "NCDatabaseTypesViewController"))
		searchController?.searchBar.searchBarStyle = UISearchBarStyle.default
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.barStyle = UIBarStyle.black
		searchController?.hidesNavigationBarDuringPresentation = false
		tableView.backgroundView = UIView()
		tableView.tableHeaderView = searchController?.searchBar
		definesPresentationContext = true
		
	}
}

//
//  NCZKillboardCategoriesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCZKillboardCategoriesViewController: NCTreeViewController, NCSearchableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.compact])
		
		setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCZKillboardTypesViewController"))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController?.content == nil {
			let request = NSFetchRequest<NCDBInvCategory>(entityName: "InvCategory")
			request.predicate = NSPredicate(format: "categoryID IN %@", [NCDBCategoryID.ship.rawValue, NCDBCategoryID.structure.rawValue])
			request.sortDescriptors = [NSSortDescriptor(key: "categoryName", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			
			treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCDatabaseCategoryRow.self)
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
		guard let row = node as? NCDatabaseCategoryRow else {return}
		Router.KillReports.Groups(category: row.object).perform(source: self, sender: treeController.cell(for: node))
	}
	
	//MARK: NCSearchableViewController
	
	var searchController: UISearchController?
	
	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCZKillboardTypesViewController else {return}
		if let text = searchController.searchBar.text, text.characters.count > 2 {
			predicate = NSPredicate(format: "published == TRUE AND group.category.categoryID IN %@ AND typeName CONTAINS[C] %@", [NCDBCategoryID.ship.rawValue, NCDBCategoryID.structure.rawValue], text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	

}

//
//  NCDatabaseCategoriesViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData


class NCDatabaseCategoryRow: NCFetchedResultsObjectNode<NCDBInvCategory> {
	
	required init(object: NCDBInvCategory) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.compact.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.categoryName
		cell.iconView?.image = object.icon?.image?.image ?? NCDBEveIcon.defaultCategory.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}

class NCDatabasePublishingSectionNode<ResultType: NSFetchRequestResult>: NCDefaultFetchedResultsSectionNode<ResultType> {
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text =  (section.name == "0" ? NSLocalizedString("Unpublished", comment: "") : NSLocalizedString("Published", comment: "")).uppercased()
	}
}

class NCDatabaseCategoriesViewController: NCTreeViewController, NCSearchableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])

		setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseTypesViewController"))
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController?.content == nil {
			let request = NSFetchRequest<NCDBInvCategory>(entityName: "InvCategory")
			request.sortDescriptors = [NSSortDescriptor(key: "published", ascending: false), NSSortDescriptor(key: "categoryName", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: "published", cacheName: nil)
			
			treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: NCDatabasePublishingSectionNode<NCDBInvCategory>.self, objectNode: NCDatabaseCategoryRow.self)
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
		Router.Database.Groups(row.object).perform(source: self, sender: treeController.cell(for: node))
	}

	
	//MARK: NCSearchableViewController
	
	var searchController: UISearchController?

	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCDatabaseTypesViewController else {return}
		if let text = searchController.searchBar.text, text.count > 2 {
			predicate = NSPredicate(format: "typeName CONTAINS[C] %@", text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	

}

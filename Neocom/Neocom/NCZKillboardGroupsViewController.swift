//
//  NCZKillboardGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCZKillboardGroupRow: NCDatabaseGroupRow {
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
	}
}


class NCZKillboardGroupsViewController: UITableViewController, UISearchResultsUpdating, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	var category: NCDBInvCategory?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])
		treeController.delegate = self
		
		setupSearchController()
		title = category?.categoryName
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController.content == nil {
			let request = NSFetchRequest<NCDBInvGroup>(entityName: "InvGroup")
			request.sortDescriptors = [NSSortDescriptor(key: "published", ascending: false), NSSortDescriptor(key: "groupName", ascending: true)]
			request.predicate = NSPredicate(format: "category == %@ AND published == TRUE AND types.@count > 0", category!)
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			
			treeController.content = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCZKillboardGroupRow.self)
			
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController.content = nil
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let row = node as? NCDatabaseGroupRow else {return}
		Router.KillReports.Types(group: row.object).perform(source: self, view: treeController.cell(for: node))
	}
	
	
	//MARK: UISearchResultsUpdating
	
	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCZKillboardTypesViewController else {return}
		if let text = searchController.searchBar.text, let category = category, text.characters.count > 2 {
			predicate = NSPredicate(format: "published == TRUE AND group.category == %@ AND typeName CONTAINS[C] %@", category, text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
	//MARK: Private
	
	private var searchController: UISearchController?
	
	private func setupSearchController() {
		searchController = UISearchController(searchResultsController: self.storyboard?.instantiateViewController(withIdentifier: "NCZKillboardTypesViewController"))
		searchController?.searchBar.searchBarStyle = UISearchBarStyle.default
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.barStyle = UIBarStyle.black
		searchController?.hidesNavigationBarDuringPresentation = false
		tableView.backgroundView = UIView()
		tableView.tableHeaderView = searchController?.searchBar
		definesPresentationContext = true
		
	}
}

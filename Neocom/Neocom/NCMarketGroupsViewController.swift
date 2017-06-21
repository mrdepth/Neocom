//
//  NCMarketGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCMarketGroupRow: FetchedResultsObjectNode<NCDBInvMarketGroup> {
	
	required init(object: NCDBInvMarketGroup) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.compact.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.marketGroupName
		cell.iconView?.image = object.icon?.image?.image ?? NCDBEveIcon.defaultGroup.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}

class NCMarketGroupsViewController: UITableViewController, UISearchResultsUpdating, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	var parentGroup: NCDBInvMarketGroup?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])
		treeController.delegate = self
		
		setupSearchController()
		title = parentGroup?.marketGroupName ?? NSLocalizedString("Market", comment: "")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController.content == nil {
			let request = NSFetchRequest<NCDBInvMarketGroup>(entityName: "InvMarketGroup")
			request.sortDescriptors = [NSSortDescriptor(key: "marketGroupName", ascending: true)]
			if let parent = parentGroup {
				request.predicate = NSPredicate(format: "parentGroup == %@", parent)
			}
			else {
				request.predicate = NSPredicate(format: "parentGroup == NULL")
			}
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			
			try? results.performFetch()
			
			treeController.content = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCMarketGroupRow.self)
			
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController.content = nil
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let row = node as? NCMarketGroupRow else {return}
		if (row.object.types?.count ?? 0) > 0 {
			Router.Database.Types(marketGroup: row.object).perform(source: self, view: treeController.cell(for: node))
		}
		else {
			Router.Database.MarketGroups(parentGroup: row.object).perform(source: self, view: treeController.cell(for: node))
		}
	}
	
	
	//MARK: UISearchResultsUpdating
	
	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCDatabaseTypesViewController else {return}
		if let text = searchController.searchBar.text, text.characters.count > 2 {
			predicate = NSPredicate(format: "marketGroup != NULL AND typeName CONTAINS[C] %@", text)
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

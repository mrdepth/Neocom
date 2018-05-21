//
//  NCMarketGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI

class NCMarketGroupRow: NCFetchedResultsObjectNode<NCDBInvMarketGroup> {
	
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

class NCMarketGroupsViewController: NCTreeViewController, NCSearchableViewController {

	var parentGroup: NCDBInvMarketGroup?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])
		
		setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseTypesViewController"))
		title = parentGroup?.marketGroupName ?? NSLocalizedString("Browse", comment: "")
	}
	
	override func content() -> Future<TreeNode?> {
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
		
		return .init(FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCMarketGroupRow.self))
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController?.content = nil
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCMarketGroupRow else {return}
		if (row.object.types?.count ?? 0) > 0 {
			Router.Database.Types(marketGroup: row.object).perform(source: self, sender: treeController.cell(for: node))
		}
		else {
			Router.Database.MarketGroups(parentGroup: row.object).perform(source: self, sender: treeController.cell(for: node))
		}
	}
	
	
	//MARK: - NCSearchableViewController
	
	var searchController: UISearchController?

	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCDatabaseTypesViewController else {return}
		if let text = searchController.searchBar.text, text.count > 2 {
			predicate = NSPredicate(format: "marketGroup != NULL AND typeName CONTAINS[C] %@", text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
	
}

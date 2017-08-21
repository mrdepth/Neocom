//
//  NCNPCViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 21.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCNPCGroupRow: NCFetchedResultsObjectNode<NCDBNpcGroup> {
	
	required init(object: NCDBNpcGroup) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.compact.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.npcGroupName
		cell.iconView?.image = object.icon?.image?.image ?? NCDBEveIcon.defaultGroup.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}

class NCNPCViewController: NCTreeViewController, NCSearchableViewController {

	var parentGroup: NCDBNpcGroup?
	
	override func viewDidLoad() {
		super.viewDidLoad()

		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])

		setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCDatabaseTypesViewController"))
		title = parentGroup?.npcGroupName ?? NSLocalizedString("NPC", comment: "")
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController?.content == nil {
			let request = NSFetchRequest<NCDBNpcGroup>(entityName: "NpcGroup")
			request.sortDescriptors = [NSSortDescriptor(key: "npcGroupName", ascending: true)]
			if let parent = parentGroup {
				request.predicate = NSPredicate(format: "parentNpcGroup == %@", parent)
			}
			else {
				request.predicate = NSPredicate(format: "parentNpcGroup == NULL")
			}
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			
			try? results.performFetch()
			
			treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCNPCGroupRow.self)
			
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
		guard let row = node as? NCNPCGroupRow else {return}
		if row.object.group != nil {
			Router.Database.Types(npcGroup: row.object).perform(source: self, view: treeController.cell(for: node))
		}
		else {
			Router.Database.NpcGroups(parentGroup: row.object).perform(source: self, view: treeController.cell(for: node))
		}
	}
	
	
	//MARK: UISearchResultsUpdating
	
	var searchController: UISearchController?

	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCDatabaseTypesViewController else {return}
		if let text = searchController.searchBar.text, text.characters.count > 2 {
			predicate = NSPredicate(format: "group.category.categoryID == 11 AND typeName CONTAINS[C] %@", text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
}

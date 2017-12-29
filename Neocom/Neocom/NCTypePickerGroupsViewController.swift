//
//  NCTypePickerGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCDgmppItemGroupRow: NCFetchedResultsObjectNode<NCDBDgmppItemGroup> {
	required init(object: NCDBDgmppItemGroup) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.compact.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.groupName
		cell.iconView?.image = object.icon?.image?.image ?? NCDBEveIcon.defaultGroup.image?.image
		cell.accessoryType = .disclosureIndicator
	}
}

class NCTypePickerGroupsViewController: NCTreeViewController, NCSearchableViewController {
	var parentGroup: NCDBDgmppItemGroup?
	
	override func viewDidLoad() {
		super.viewDidLoad()

		setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCTypePickerTypesViewController"))

		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])
		title = parentGroup?.groupName
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		//title = group?.groupName
		if treeController?.content == nil {
			guard let parentGroup = parentGroup else {return}
			let request = NSFetchRequest<NCDBDgmppItemGroup>(entityName: "DgmppItemGroup")
			request.sortDescriptors = [NSSortDescriptor(key: "groupName", ascending: true)]
			request.predicate = NSPredicate(format: "parentGroup == %@", parentGroup)
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			
			
			treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCDgmppItemGroupRow.self)
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController?.content = nil
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCDatabaseTypesViewController" {
			let controller = segue.destination as? NCDatabaseTypesViewController
			let group = (sender as! NCDefaultTableViewCell).object as! NCDBInvGroup
			controller?.predicate = NSPredicate(format: "group = %@", group)
			controller?.title = group.groupName
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCDgmppItemGroupRow else {return}
		if row.object.subGroups?.count ?? 0 > 0 {
			Router.Database.TypePickerGroups(parentGroup: row.object).perform(source: self, sender: treeController.cell(for: node))
		}
		else {
			Router.Database.TypePickerTypes(group: row.object).perform(source: self, sender: treeController.cell(for: node))
		}
	}

	//MARK: - NCSearchableViewController
	
	var searchController: UISearchController?
	
	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCTypePickerTypesViewController else {return}
		if let text = searchController.searchBar.text, let category = parentGroup?.category, text.count > 1 {
			predicate = NSPredicate(format: "ANY dgmppItem.groups.category == %@ AND typeName CONTAINS[C] %@ AND published == YES", category, text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}

}

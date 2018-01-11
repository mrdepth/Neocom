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
		
		let button = UIButton(type: .system)
		button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
		button.setTitle(NSLocalizedString("Select", comment: "").uppercased(), for: .normal)
		button.sizeToFit()
		cell.accessoryButtonHandler = NCActionHandler(button, for: .touchUpInside) { [weak self] _ in
			guard let strongSelf = self else {return}
			guard let controller = strongSelf.treeController else {return}
			controller.delegate?.treeController?(controller, accessoryButtonTappedWithNode: strongSelf)
		}
		
		cell.accessoryView = button

	}
}


class NCZKillboardGroupsViewController: NCTreeViewController, NCSearchableViewController {
	var category: NCDBInvCategory?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.compact])
		
		setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCZKillboardTypesViewController"))
		title = category?.categoryName
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController?.content == nil {
			let request = NSFetchRequest<NCDBInvGroup>(entityName: "InvGroup")
			request.sortDescriptors = [NSSortDescriptor(key: "published", ascending: false), NSSortDescriptor(key: "groupName", ascending: true)]
			request.predicate = NSPredicate(format: "category == %@ AND published == TRUE AND types.@count > 0", category!)
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			
			treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCZKillboardGroupRow.self)
			
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
		guard let row = node as? NCDatabaseGroupRow else {return}
		Router.KillReports.Types(group: row.object).perform(source: self, sender: treeController.cell(for: node))
	}
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		guard let row = node as? NCDatabaseGroupRow else {return}
		guard let picker = (navigationController as? NCZKillboardTypePickerViewController) ?? presentingViewController?.navigationController as? NCZKillboardTypePickerViewController else {return}
		picker.completionHandler(picker, row.object)

	}
	
	//MARK: NCSearchableViewController
	
	var searchController: UISearchController?

	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCZKillboardTypesViewController else {return}
		if let text = searchController.searchBar.text, let category = category, text.count > 2 {
			predicate = NSPredicate(format: "published == TRUE AND group.category == %@ AND typeName CONTAINS[C] %@", category, text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
}

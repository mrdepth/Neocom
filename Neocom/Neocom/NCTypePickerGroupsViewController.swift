//
//  NCTypePickerGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11.01.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCTypePickerGroupsViewController: UITableViewController, UISearchResultsUpdating {
	private var results: NSFetchedResultsController<NCDBDgmppItemGroup>?
	private var searchController: UISearchController?
	var group: NCDBDgmppItemGroup?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		setupSearchController()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		title = group?.groupName
		if results == nil {
			guard let group = group else {return}
			let request = NSFetchRequest<NCDBDgmppItemGroup>(entityName: "DgmppItemGroup")
			request.sortDescriptors = [NSSortDescriptor(key: "groupName", ascending: true)]
			request.predicate = NSPredicate(format: "parentGroup == %@", group)
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			try? results.performFetch()
			self.results = results
			tableView.reloadData()
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			results = nil
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
	
	//MARK: UITableViewDataSource
	
	override func numberOfSections(in tableView: UITableView) -> Int {
		return results?.sections?.count ?? 0
	}
	
	override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return results?.sections?[section].numberOfObjects ?? 0
	}
	
	override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) as! NCDefaultTableViewCell
		let object = results?.object(at: indexPath)
		cell.object = object
		cell.titleLabel?.text = object?.groupName
		cell.iconView?.image = object?.icon?.image?.image ?? NCDBEveIcon.defaultGroup.image?.image
		return cell
	}
	
	override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		if let name = self.results?.sections?[section].name, name == "0" {
			return NSLocalizedString("Unpublished", comment: "")
		}
		else {
			return nil
		}
	}
	
	//MARK: UITableViewDelegate
	
	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		guard let object = results?.object(at: indexPath) else {return}
		if object.subGroups?.count ?? 0 > 0 {
			guard let controller = storyboard?.instantiateViewController(withIdentifier: "NCTypePickerGroupsViewController") as? NCTypePickerGroupsViewController else {return}
			controller.group = object
			show(controller, sender: tableView.cellForRow(at: indexPath))
		}
		else {
			guard let controller = storyboard?.instantiateViewController(withIdentifier: "NCTypePickerTypesViewController") as? NCTypePickerTypesViewController else {return}
			controller.predicate = NSPredicate(format: "dgmppItem.groups CONTAINS %@", object)
			show(controller, sender: tableView.cellForRow(at: indexPath))
		}
	}
	
	//MARK: UISearchResultsUpdating
	
	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCTypePickerTypesViewController else {return}
		if let text = searchController.searchBar.text, let category = group?.category, text.utf8.count > 1 {
			predicate = NSPredicate(format: "ANY dgmppItem.groups.category == %@ AND typeName CONTAINS[C] %@", category, text)
		}
		else {
			predicate = NSPredicate(value: false)
		}
		controller.predicate = predicate
		controller.reloadData()
	}
	
	//MARK: Private
	
	private func setupSearchController() {
		searchController = UISearchController(searchResultsController: self.storyboard?.instantiateViewController(withIdentifier: "NCTypePickerTypesViewController"))
		searchController?.searchBar.searchBarStyle = UISearchBarStyle.default
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.barStyle = UIBarStyle.black
		searchController?.hidesNavigationBarDuringPresentation = false
		tableView.backgroundView = UIView()
		tableView.tableHeaderView = searchController?.searchBar
		definesPresentationContext = true
		
	}
}

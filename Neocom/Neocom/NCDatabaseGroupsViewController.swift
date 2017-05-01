//
//  NCDatabaseGroupsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 08.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCDatabaseGroupsViewController: UITableViewController, UISearchResultsUpdating {
	private var results: NSFetchedResultsController<NCDBInvGroup>?
	private var searchController: UISearchController?
	var category: NCDBInvCategory?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		setupSearchController()
		title = category?.categoryName
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if results == nil {
			let request = NSFetchRequest<NCDBInvGroup>(entityName: "InvGroup")
			request.sortDescriptors = [NSSortDescriptor(key: "published", ascending: false), NSSortDescriptor(key: "groupName", ascending: true)]
			request.predicate = NSPredicate(format: "category == %@ AND types.@count > 0", category!)
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: "published", cacheName: nil)
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
	
	//MARK: UISearchResultsUpdating
	
	func updateSearchResults(for searchController: UISearchController) {
		let predicate: NSPredicate
		guard let controller = searchController.searchResultsController as? NCDatabaseTypesViewController else {return}
		if let text = searchController.searchBar.text, let category = category, text.characters.count > 2 {
			predicate = NSPredicate(format: "group.category == %@ AND typeName CONTAINS[C] %@", category, text)
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

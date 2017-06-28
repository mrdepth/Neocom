//
//  NCZKillboardSolarSystemsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCSolarSystemRow: FetchedResultsObjectNode<NCDBMapSolarSystem> {
	
	lazy var title: NSAttributedString = {
		return NCLocation(self.object).displayName
	}()
	
	required init(object: NCDBMapSolarSystem) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.noImage.reuseIdentifier
	}
	
	var handler: NCActionHandler?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.attributedText = title
	}
}

class NCZKillboardSolarSystemsViewController: UITableViewController, UISearchResultsUpdating, TreeControllerDelegate {
	
	@IBOutlet var treeController: TreeController!
	var region: NCDBMapRegion?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCHeaderTableViewCell.default])
		treeController.delegate = self
		title = region?.regionName
		
		setupSearchController()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if let region = region, treeController.content == nil {
			let request = NSFetchRequest<NCDBMapSolarSystem>(entityName: "MapSolarSystem")
			request.predicate = NSPredicate(format: "constellation.region == %@", region)
			request.sortDescriptors = [NSSortDescriptor(key: "solarSystemName", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			
			treeController.content = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCSolarSystemRow.self)
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController.content = nil
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let row = node as? NCSolarSystemRow else {return}
		guard let picker = (navigationController as? NCZKillboardRegionPickerViewController) ?? presentingViewController?.navigationController as? NCZKillboardRegionPickerViewController else {return}
		picker.completionHandler(picker, row.object)
	}
	
	//MARK: UISearchResultsUpdating
	
	private var searchController: UISearchController?
	
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
	
	//MARK: Private
	
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

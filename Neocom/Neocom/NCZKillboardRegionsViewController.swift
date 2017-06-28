//
//  NCZKillboardRegionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCRegionRow: FetchedResultsObjectNode<NCDBMapRegion> {
	
	required init(object: NCDBMapRegion) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.noImage.reuseIdentifier
	}
	
	var handler: NCActionHandler?
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.regionName
		
		let button = UIButton(type: .system)
		button.titleLabel?.font = UIFont.preferredFont(forTextStyle: .subheadline)
		button.setTitle(NSLocalizedString("Select", comment: "").uppercased(), for: .normal)
		button.sizeToFit()
		self.handler = NCActionHandler(button, for: .touchUpInside) { [weak self] _ in
			guard let strongSelf = self else {return}
			guard let controller = strongSelf.treeController else {return}
			controller.delegate?.treeController?(controller, accessoryButtonTappedWithNode: strongSelf)
		}
		
		cell.accessoryView = button
	}
}

class NCZKillboardRegionsViewController: UITableViewController, UISearchResultsUpdating, TreeControllerDelegate {
	
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCHeaderTableViewCell.default])
		treeController.delegate = self
		
		setupSearchController()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController.content == nil {
			let request = NSFetchRequest<NCDBMapRegion>(entityName: "MapRegion")
			request.sortDescriptors = [NSSortDescriptor(key: "securityClass", ascending: false), NSSortDescriptor(key: "regionName", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: "securityClassDisplayName", cacheName: nil)
			
			treeController.content = FetchedResultsNode(resultsController: results, sectionNode: NCDefaultFetchedResultsSectionNode<NCDBMapRegion>.self, objectNode: NCRegionRow.self)
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController.content = nil
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let row = node as? NCRegionRow else {return}
		Router.KillReports.SolarSystems(region: row.object).perform(source: self, view: treeController.cell(for: node))
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		guard let row = node as? NCRegionRow else {return}
		guard let picker = (navigationController as? NCZKillboardRegionPickerViewController) ?? presentingViewController?.navigationController as? NCZKillboardRegionPickerViewController else {return}
		picker.completionHandler(picker, row.object)
		
	}
	
	//MARK: UISearchResultsUpdating
	
	private var searchController: UISearchController?
	
	func updateSearchResults(for searchController: UISearchController) {
		guard let controller = searchController.searchResultsController as? NCZKillboardRegionsSearchResultsViewController else {return}
		controller.update(searchString: searchController.searchBar.text ?? "")
	}
	
	//MARK: Private
	
	private func setupSearchController() {
		searchController = UISearchController(searchResultsController: self.storyboard?.instantiateViewController(withIdentifier: "NCZKillboardRegionsSearchResultsViewController"))
		searchController?.searchBar.searchBarStyle = UISearchBarStyle.default
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.barStyle = UIBarStyle.black
		searchController?.hidesNavigationBarDuringPresentation = false
		tableView.backgroundView = UIView()
		tableView.tableHeaderView = searchController?.searchBar
		definesPresentationContext = true
		
	}
}

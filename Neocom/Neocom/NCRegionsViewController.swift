//
//  NCRegionsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCRegionRow: NCFetchedResultsObjectNode<NCDBMapRegion> {
	
	required init(object: NCDBMapRegion) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.noImage.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = object.regionName
	}
}

class NCRegionSelectionRow: NCRegionRow {
	
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

class NCRegionsViewController: NCTreeViewController, NCSearchableViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCHeaderTableViewCell.default])
		
		setupSearchController(searchResultsController: self.storyboard!.instantiateViewController(withIdentifier: "NCLocationSearchResultsViewController"))
	}
	
	var mode: [NCLocationPickerViewController.Mode] {
		return (navigationController as? NCLocationPickerViewController)?.mode ?? []
	}

	override func updateContent(completionHandler: @escaping () -> Void) {
		let request = NSFetchRequest<NCDBMapRegion>(entityName: "MapRegion")
		request.sortDescriptors = [NSSortDescriptor(key: "securityClass", ascending: false), NSSortDescriptor(key: "regionName", ascending: true)]
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: "securityClassDisplayName", cacheName: nil)
		
		if mode.contains(.regions) {
			treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: NCDefaultFetchedResultsSectionNode<NCDBMapRegion>.self, objectNode: NCRegionSelectionRow.self)
		}
		else {
			treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: NCDefaultFetchedResultsSectionNode<NCDBMapRegion>.self, objectNode: NCRegionRow.self)
		}
		completionHandler()
	}
	
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCRegionRow else {return}
		if mode.contains(.solarSystems) {
			Router.Database.SolarSystems(region: row.object).perform(source: self, view: treeController.cell(for: node))
		}
		else {
			guard let picker = navigationController as? NCLocationPickerViewController else {return}
			picker.completionHandler(picker, row.object)
		}
	}
	
	override func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		super.treeController(treeController, accessoryButtonTappedWithNode: node)
		guard let row = node as? NCRegionRow else {return}
		guard let picker = navigationController as? NCLocationPickerViewController else {return}
		picker.completionHandler(picker, row.object)
		
	}
	
	//MARK: NCSearchableViewController
	
	var searchController: UISearchController?
	
	func updateSearchResults(for searchController: UISearchController) {
		guard let controller = searchController.searchResultsController as? NCLocationSearchResultsViewController else {return}
		controller.updateSearchResults(for: searchController)
	}
	
}

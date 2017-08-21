//
//  NCSolarSystemsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCSolarSystemRow: NCFetchedResultsObjectNode<NCDBMapSolarSystem> {
	
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

class NCSolarSystemsViewController: NCTreeViewController, NCSearchableViewController {
	
	var region: NCDBMapRegion?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCHeaderTableViewCell.default])
		title = region?.regionName
		
		let controller = self.storyboard!.instantiateViewController(withIdentifier: "NCLocationSearchResultsViewController") as! NCLocationSearchResultsViewController
		controller.region = region
		setupSearchController(searchResultsController: controller)
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let region = region {
			let request = NSFetchRequest<NCDBMapSolarSystem>(entityName: "MapSolarSystem")
			request.predicate = NSPredicate(format: "constellation.region == %@", region)
			request.sortDescriptors = [NSSortDescriptor(key: "solarSystemName", ascending: true)]
			let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)
			
			treeController?.content = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCSolarSystemRow.self)
		}

		completionHandler()
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCSolarSystemRow else {return}
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

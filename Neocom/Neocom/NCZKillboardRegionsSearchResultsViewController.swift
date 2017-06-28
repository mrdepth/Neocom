//
//  NCZKillboardRegionsSearchResultsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCZKillboardRegionsSearchResultsRow: TreeRow {
	
	let objectID: NSManagedObjectID
	
	lazy var location: NSManagedObject? = {
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return nil}
		return try? context.existingObject(with: self.objectID)
	}()
	
	init(objectID: NSManagedObjectID) {
		self.objectID = objectID
		super.init(prototype: Prototype.NCDefaultTableViewCell.noImage)
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		if let region = location as? NCDBMapRegion {
			cell.titleLabel?.text = region.regionName
			cell.subtitleLabel?.text = nil
		}
		else if let solarSystem = location as? NCDBMapSolarSystem {
			cell.titleLabel?.attributedText = NCLocation(solarSystem).displayName
			cell.subtitleLabel?.text = solarSystem.constellation?.region?.regionName
		}
	}
}

class NCZKillboardRegionsSearchResultsViewController: UITableViewController, TreeControllerDelegate {
	@IBOutlet var treeController: TreeController!
	
	private var searchController: UISearchController?
	private let gate = NCGate()
	var region: NCDBMapRegion?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.noImage])
		treeController.delegate = self
		
	}
	
	func update(searchString: String) {
		if !searchString.isEmpty {
			gate.perform {
				NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
					var sections = [TreeNode]()
					if let region = self.region {
						let request = NSFetchRequest<NSManagedObjectID>(entityName: "MapSolarSystem")
						request.resultType = .managedObjectIDResultType
						request.sortDescriptors = [NSSortDescriptor(key: "solarSystemName", ascending: true)]
						request.predicate = NSPredicate(format: "constellation.region == %@ AND solarSystemName CONTAINS[C] %@", region, searchString)
						let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
						try? results.performFetch()
						if let rows = results.fetchedObjects?.map ({NCZKillboardRegionsSearchResultsRow(objectID: $0)}), !rows.isEmpty {
							sections.append(DefaultTreeSection(nodeIdentifier: "SolarSystems", title: NSLocalizedString("Solar Systems", comment: "").uppercased(), children: rows))
						}
					}
					else {
						var request = NSFetchRequest<NSManagedObjectID>(entityName: "MapRegion")
						request.resultType = .managedObjectIDResultType
						request.sortDescriptors = [NSSortDescriptor(key: "regionName", ascending: true)]
						request.predicate = NSPredicate(format: "regionName CONTAINS[C] %@", searchString)
						var results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
						try? results.performFetch()
						if let rows = results.fetchedObjects?.map ({NCZKillboardRegionsSearchResultsRow(objectID: $0)}), !rows.isEmpty {
							sections.append(DefaultTreeSection(nodeIdentifier: "Regions", title: NSLocalizedString("Regions", comment: "").uppercased(), children: rows))
						}
						
						request = NSFetchRequest<NSManagedObjectID>(entityName: "MapSolarSystem")
						request.resultType = .managedObjectIDResultType
						request.sortDescriptors = [NSSortDescriptor(key: "solarSystemName", ascending: true)]
						request.predicate = NSPredicate(format: "solarSystemName CONTAINS[C] %@", searchString)
						results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
						try? results.performFetch()
						if let rows = results.fetchedObjects?.map ({NCZKillboardRegionsSearchResultsRow(objectID: $0)}), !rows.isEmpty {
							sections.append(DefaultTreeSection(nodeIdentifier: "SolarSystems", title: NSLocalizedString("Solar Systems", comment: "").uppercased(), children: rows))
						}
						
					}
					
					DispatchQueue.main.async {
						self.treeController.content = RootNode(sections)
						
						self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
					}
				})
			}
		}
		else {
			self.treeController.content = TreeNode()
			self.tableView.backgroundView = nil
		}
		

	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			treeController.content = nil
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let row = node as? NCZKillboardRegionsSearchResultsRow else {return}
		guard let picker = (navigationController as? NCZKillboardRegionPickerViewController) ?? presentingViewController?.navigationController as? NCZKillboardRegionPickerViewController else {return}
		guard let location = row.location else {return}
		picker.completionHandler(picker, location)
	}
	
}

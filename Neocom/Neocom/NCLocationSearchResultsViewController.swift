//
//  NCLocationSearchResultsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 01.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCSearchResultsSolarSystemRow: FetchedResultsObjectNode<NSManagedObjectID> {
	
	lazy var solarSystem: NCDBMapSolarSystem? = {
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return nil}
		return (try? context.existingObject(with: self.object)) as? NCDBMapSolarSystem
	}()
	
	required init(object: NSManagedObjectID) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.noImage.reuseIdentifier
	}

	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		if let solarSystem = solarSystem {
			cell.titleLabel?.attributedText = NCLocation(solarSystem).displayName
			cell.subtitleLabel?.text = solarSystem.constellation?.region?.regionName
		}
		else {
			cell.titleLabel?.text = nil
			cell.subtitleLabel?.text = nil
		}
	}
}

class NCSearchResultsRegionRow: FetchedResultsObjectNode<NSManagedObjectID> {
	
	lazy var region: NCDBMapRegion? = {
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return nil}
		return (try? context.existingObject(with: self.object)) as? NCDBMapRegion
	}()
	
	lazy var solarSystem: NCDBMapSolarSystem? = {
		guard let context = NCDatabase.sharedDatabase?.viewContext else {return nil}
		return (try? context.existingObject(with: self.object)) as? NCDBMapSolarSystem
	}()

	required init(object: NSManagedObjectID) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.noImage.reuseIdentifier
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		if let region = region {
			cell.titleLabel?.text = region.regionName
			cell.subtitleLabel?.text = nil
		}
		else if let solarSystem = solarSystem {
			cell.titleLabel?.text = solarSystem.constellation?.region?.regionName
			cell.subtitleLabel?.text = solarSystem.solarSystemName
		}
		else {
			cell.titleLabel?.text = nil
			cell.subtitleLabel?.text = nil
		}
	}
}


class NCLocationSearchResultsViewController: NCTreeViewController, UISearchResultsUpdating {
	
	var region: NCDBMapRegion?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.noImage])
		
	}

	private let gate = NCGate()

	func updateSearchResults(for searchController: UISearchController) {
		if let searchString = searchController.searchBar.text, !searchString.isEmpty {
			let mode = (presentingViewController?.navigationController as? NCLocationPickerViewController)?.mode ?? NCLocationPickerViewController.Mode.all
			
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
						
						if results.fetchedObjects?.isEmpty == false {
							let node = FetchedResultsNode(resultsController: results, sectionNode: NCDefaultFetchedResultsSectionNode<NSManagedObjectID>.self, objectNode: NCSearchResultsRegionRow.self)
							sections.append(DefaultTreeSection(nodeIdentifier: "SolarSystems", title: NSLocalizedString("Solar Systems", comment: "").uppercased(), children: [node]))
						}
					}
					else {
						if mode.contains(.regions) {
							let request = NSFetchRequest<NSManagedObjectID>(entityName: "MapRegion")
							request.resultType = .managedObjectIDResultType
							request.sortDescriptors = [NSSortDescriptor(key: "regionName", ascending: true)]
							request.predicate = NSPredicate(format: "regionName CONTAINS[C] %@", searchString)
							
							let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
							try? results.performFetch()
							
							if results.fetchedObjects?.isEmpty == false {
								let node = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCSearchResultsRegionRow.self)
								sections.append(DefaultTreeSection(nodeIdentifier: "Regions", title: NSLocalizedString("Regions", comment: "").uppercased(), children: [node]))
							}

							if !mode.contains(.solarSystems) {
								let request = NSFetchRequest<NSManagedObjectID>(entityName: "MapSolarSystem")
								request.resultType = .managedObjectIDResultType
								request.sortDescriptors = [NSSortDescriptor(key: "constellation.region.regionName", ascending: true)]
								request.predicate = NSPredicate(format: "constellation.region.regionID < %d AND solarSystemName CONTAINS[C] %@", NCDBRegionID.whSpace.rawValue, searchString)
								let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: NCDatabase.sharedDatabase!.viewContext, sectionNameKeyPath: nil, cacheName: nil)

								try? results.performFetch()
								if results.fetchedObjects?.isEmpty == false {
									let node = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCSearchResultsRegionRow.self)
									sections.append(node)
								}
							}

							
						}
						
						if mode.contains(.solarSystems) {
							let request = NSFetchRequest<NSManagedObjectID>(entityName: "MapSolarSystem")
							request.resultType = .managedObjectIDResultType
							request.sortDescriptors = [NSSortDescriptor(key: "solarSystemName", ascending: true)]
							request.predicate = NSPredicate(format: "solarSystemName CONTAINS[C] %@", searchString)
							let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
							try? results.performFetch()
							
							if results.fetchedObjects?.isEmpty == false {
								let node = FetchedResultsNode(resultsController: results, sectionNode: nil, objectNode: NCSearchResultsSolarSystemRow.self)
								sections.append(DefaultTreeSection(nodeIdentifier: "SolarSystems", title: NSLocalizedString("Solar Systems", comment: "").uppercased(), children: [node]))
							}
						}
						
						
					}
					
					DispatchQueue.main.async {
						self.treeController?.content = RootNode(sections)
						self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
					}
				})
			}
		}
		else {
			self.treeController?.content = TreeNode()
			self.tableView.backgroundView = nil
		}
		
		
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let picker = presentingViewController?.navigationController as? NCLocationPickerViewController else {return}
		guard let location = (node as? NCSearchResultsSolarSystemRow)?.solarSystem ?? (node as? NCSearchResultsRegionRow)?.region ?? (node as? NCSearchResultsRegionRow)?.solarSystem?.constellation?.region else {return}
		picker.completionHandler(picker, location)
	}
	
}

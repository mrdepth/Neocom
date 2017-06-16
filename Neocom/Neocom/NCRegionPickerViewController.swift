//
//  NCRegionPickerViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 26.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData

class NCRegionPickerRow: TreeRow {
	let regionID: NSManagedObjectID?
	let solarSystemID: NSManagedObjectID?
	let selected: Bool
	lazy var region: NCDBMapRegion? = {
		guard let regionID = self.regionID else {return nil}
		guard let region = (try? NCDatabase.sharedDatabase!.viewContext.existingObject(with: regionID)) as? NCDBMapRegion else {return nil}
		return region
	}()

	lazy var solarSystem: NCDBMapSolarSystem? = {
		guard let solarSystemID = self.solarSystemID else {return nil}
		guard let solarSystem = (try? NCDatabase.sharedDatabase!.viewContext.existingObject(with: solarSystemID)) as? NCDBMapSolarSystem else {return nil}
		return solarSystem
	}()

	init(regionID: NSManagedObjectID, selected: Bool) {
		self.regionID = regionID
		self.solarSystemID = nil
		self.selected = selected
		super.init(prototype: Prototype.NCDefaultTableViewCell.default)
	}
	init(solarSystemID: NSManagedObjectID, selected: Bool) {
		self.regionID = nil
		self.solarSystemID = solarSystemID
		self.selected = selected
		super.init(prototype: Prototype.NCDefaultTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCDefaultTableViewCell
		if let region = region {
			cell.titleLabel?.text = region.regionName
			cell.subtitleLabel?.text = nil
		}
		else if let solarSystem = solarSystem {
			cell.titleLabel?.text = solarSystem.constellation?.region?.regionName
			cell.subtitleLabel?.text = solarSystem.solarSystemName
		}
		else {
			cell.titleLabel = nil
			cell.subtitleLabel = nil
		}
		cell.accessoryView = selected ? UIImageView(image: #imageLiteral(resourceName: "checkmark")) : nil
		
	}
}

class NCRegionPickerViewController: UITableViewController, UISearchResultsUpdating, TreeControllerDelegate {
	private var results: NSFetchedResultsController<NCDBMapRegion>?
	private var searchController: UISearchController?
	var region: NCDBMapRegion?
	var searchString: String?
	
	private let gate = NCGate()
	@IBOutlet weak var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		let regionID = UserDefaults.standard.object(forKey: UserDefaults.Key.NCMarketRegion) as? Int ?? NCDBRegionID.theForge.rawValue
		self.region = NCDatabase.sharedDatabase?.mapRegions[regionID]
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCHeaderTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.default])
		
		treeController.delegate = self

		if navigationController != nil {
			setupSearchController()
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if results == nil {
			reloadData()
		}
	}
	
	func reloadData() {
		let selection = region?.objectID
		gate.perform {
			NCDatabase.sharedDatabase?.performTaskAndWait({ (managedObjectContext) in
				var sections = [TreeSection]()
				var knownSpace = [NCRegionPickerRow]()
				var whSpace = [NCRegionPickerRow]()
				if let searchString = self.searchString {
					let regions = NSFetchRequest<NSManagedObjectID>(entityName: "MapRegion")
					regions.resultType = .managedObjectIDResultType
					regions.sortDescriptors = [NSSortDescriptor(key: "regionName", ascending: true)]
					regions.predicate = NSPredicate(format: "regionID < %d AND regionName CONTAINS[C] %@", NCDBRegionID.whSpace.rawValue, searchString)
					if let results = try? managedObjectContext.fetch(regions) {
						knownSpace.append(contentsOf: results.map {return NCRegionPickerRow(regionID: $0, selected: $0 == selection)})
					}
					
					regions.predicate = NSPredicate(format: "regionID >= %d AND regionName CONTAINS[C] %@", NCDBRegionID.whSpace.rawValue, searchString)
					if let results = try? managedObjectContext.fetch(regions) {
						whSpace.append(contentsOf: results.map {return NCRegionPickerRow(regionID: $0, selected: $0 == selection)})
					}
					
					let solarSystems = NSFetchRequest<NSManagedObjectID>(entityName: "MapSolarSystem")
					solarSystems.resultType = .managedObjectIDResultType
					solarSystems.sortDescriptors = [NSSortDescriptor(key: "constellation.region.regionName", ascending: true)]
					solarSystems.predicate = NSPredicate(format: "constellation.region.regionID < %d AND solarSystemName CONTAINS[C] %@", NCDBRegionID.whSpace.rawValue, searchString)
					if let results = try? managedObjectContext.fetch(solarSystems) {
						knownSpace.append(contentsOf: results.map {return NCRegionPickerRow(solarSystemID: $0, selected: $0 == selection)})
					}
					
					solarSystems.predicate = NSPredicate(format: "constellation.region.regionID >= %d AND solarSystemName CONTAINS[C] %@", NCDBRegionID.whSpace.rawValue, searchString)
					if let results = try? managedObjectContext.fetch(solarSystems) {
						whSpace.append(contentsOf: results.map {return NCRegionPickerRow(solarSystemID: $0, selected: $0 == selection)})
					}
					
				}
				else {
					let request = NSFetchRequest<NSManagedObjectID>(entityName: "MapRegion")
					request.resultType = .managedObjectIDResultType
					request.sortDescriptors = [NSSortDescriptor(key: "regionName", ascending: true)]
					request.predicate = NSPredicate(format: "regionID < %d", NCDBRegionID.whSpace.rawValue)
					if let results = try? managedObjectContext.fetch(request) {
						knownSpace.append(contentsOf: results.map {return NCRegionPickerRow(regionID: $0, selected: $0 == selection)})
					}
					request.predicate = NSPredicate(format: "regionID >= %d", NCDBRegionID.whSpace.rawValue)
					if let results = try? managedObjectContext.fetch(request) {
						whSpace.append(contentsOf: results.map {return NCRegionPickerRow(regionID: $0, selected: $0 == selection)})
					}
				}
				if knownSpace.count > 0 {
					sections.append(DefaultTreeSection(nodeIdentifier: "KnownSpace", title: NSLocalizedString("Known Space", comment: "").uppercased(), children: knownSpace))
				}
				if whSpace.count > 0 {
					sections.append(DefaultTreeSection(nodeIdentifier: "WHSpace", title: NSLocalizedString("WH Space", comment: "").uppercased(), children: whSpace))
				}
				
				DispatchQueue.main.async {
					if self.treeController.content == nil {
						let root = TreeNode()
						root.children = sections
						self.treeController.content = root
					}
					else {
						self.treeController.content?.children = sections
					}

					self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
				}
			})
		}
	}
	
	override func didReceiveMemoryWarning() {
		if !isViewLoaded || view.window == nil {
			results = nil
		}
	}
	
	override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
		if segue.identifier == "NCDatabaseGroupsViewController" {
			let controller = segue.destination as? NCDatabaseGroupsViewController
			controller?.category = (sender as? NCDefaultTableViewCell)?.object as? NCDBInvCategory
		}
	}
	
	
	//MARK: TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		guard let item = node as? NCRegionPickerRow else {return}
		
		if let region = item.region ?? item.solarSystem?.constellation?.region {
			if let parent = presentingViewController as? NCRegionPickerViewController {
				dismiss(animated: true) {
					parent.region = region
					parent.performSegue(withIdentifier: "Unwind", sender: nil)
				}
			}
			else {
				self.region = region
				performSegue(withIdentifier: "Unwind", sender: nil)
			}
		}
	}
	
	//MARK: UISearchResultsUpdating
	
	func updateSearchResults(for searchController: UISearchController) {
		guard let controller = searchController.searchResultsController as? NCRegionPickerViewController else {return}
		if let text = searchController.searchBar.text, text.characters.count > 2 {
			controller.searchString = text
		}
		else {
			controller.searchString = nil
		}
		controller.reloadData()
	}
	
	//MARK: Private
	
	private func setupSearchController() {
		searchController = UISearchController(searchResultsController: self.storyboard?.instantiateViewController(withIdentifier: "NCRegionPickerViewController"))
		searchController?.searchBar.searchBarStyle = UISearchBarStyle.default
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.barStyle = UIBarStyle.black
		searchController?.hidesNavigationBarDuringPresentation = false
		tableView.backgroundView = UIView()
		tableView.tableHeaderView = searchController?.searchBar
		definesPresentationContext = true
		
	}
}

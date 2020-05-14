//
//  NCLocationPickerRecentViewContrller.swift
//  Neocom
//
//  Created by Artem Shimanski on 02.08.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CoreData
import EVEAPI
import Futures

class NCRecentLocationRow: NCFetchedResultsObjectNode<NCCacheLocationPickerRecent> {
	required init(object: NCCacheLocationPickerRecent) {
		super.init(object: object)
		cellIdentifier = Prototype.NCDefaultTableViewCell.noImage.reuseIdentifier
	}
	
	lazy var title: NSAttributedString? = {
		if let region = NCDatabase.sharedDatabase?.mapRegions[Int(self.object.locationID)]?.regionName {
			return NSAttributedString(string: region)
		}
		else if let solarSystem = NCDatabase.sharedDatabase?.mapSolarSystems[Int(self.object.locationID)] {
			return NCLocation(solarSystem).displayName
		}
		else {
			return nil
		}
	}()
	
	lazy var region: NCDBMapRegion? = {
		guard NCCacheLocationPickerRecent.LocationType(rawValue: self.object.locationType) == .region else {return nil}
		return NCDatabase.sharedDatabase?.mapRegions[Int(self.object.locationID)]
	}()

	lazy var solarSystem: NCDBMapSolarSystem? = {
		guard NCCacheLocationPickerRecent.LocationType(rawValue: self.object.locationType) == .solarSystem else {return nil}
		return NCDatabase.sharedDatabase?.mapSolarSystems[Int(self.object.locationID)]
	}()

	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.attributedText = title
		cell.subtitleLabel?.text = solarSystem?.constellation?.region?.regionName
	}
}

class NCLocationPickerRecentViewContrller: NCTreeViewController {
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCHeaderTableViewCell.default])
	}
	
	var mode: [NCLocationPickerViewController.Mode] {
		return (navigationController as? NCLocationPickerViewController)?.mode ?? []
	}
	
	override func content() -> Future<TreeNode?> {
		guard let context = NCCache.sharedCache?.viewContext else {return .init(nil)}
		
		let request = NSFetchRequest<NCCacheLocationPickerRecent>(entityName: "LocationPickerRecent")

		if mode != NCLocationPickerViewController.Mode.all {
			if mode.contains(.regions) {
				request.predicate = NSPredicate(format: "locationType == %d", NCCacheLocationPickerRecent.LocationType.region.rawValue)
			}
			else if mode.contains(.solarSystems) {
				request.predicate = NSPredicate(format: "locationType == %d", NCCacheLocationPickerRecent.LocationType.solarSystem.rawValue)
			}
		}
		request.sortDescriptors = [NSSortDescriptor(key: "locationType", ascending: true), NSSortDescriptor(key: "date", ascending: false)]
		
		let results = NSFetchedResultsController(fetchRequest: request, managedObjectContext: context, sectionNameKeyPath: "locationTypeDisplayName", cacheName: nil)
		
		return .init(FetchedResultsNode(resultsController: results, sectionNode: NCDefaultFetchedResultsSectionNode<NCCacheLocationPickerRecent>.self, objectNode: NCRecentLocationRow.self))
	}
	
	//MARK: - TreeControllerDelegate
	
	override func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		super.treeController(treeController, didSelectCellWithNode: node)
		guard let row = node as? NCRecentLocationRow else {return}
		guard let location = row.region ?? row.solarSystem else {return}
		guard let picker = navigationController as? NCLocationPickerViewController else {return}
		picker.completionHandler(picker, location)
	}
}

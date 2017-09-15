//
//  NCDatabaseMarketInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData

class NCDatabaseMarketInfoRow: TreeRow {
	let price: String
	let location: NSAttributedString
	let quantity: String
	let order: ESI.Market.Order
	
	init(order: ESI.Market.Order, location: NCLocation?) {
		self.order = order
		self.price = NCUnitFormatter.localizedString(from: order.price, unit: .isk, style: .full)
		self.location = location?.displayName ?? NSAttributedString(string: NSLocalizedString("Unknown location", comment: ""))
		self.quantity = NCUnitFormatter.localizedString(from: Double(order.volumeRemain), unit: .none, style: .full)
		super.init(prototype: Prototype.NCMarketInfoTableViewCell.default)
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCMarketInfoTableViewCell;
		cell.priceLabel.text = price
		cell.locationLabel.attributedText = location
		cell.quantityLabel.text = quantity
	}
	
	override var hashValue: Int {
		return order.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCDatabaseMarketInfoRow)?.hashValue == hashValue
	}
}

class NCDatabaseMarketInfoViewController: NCTreeViewController {
	var type: NCDBInvType?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
		let regionID = UserDefaults.standard.object(forKey: UserDefaults.Key.NCMarketRegion) as? Int ?? NCDBRegionID.theForge.rawValue
		if let region = NCDatabase.sharedDatabase?.mapRegions[regionID] {
			navigationItem.rightBarButtonItem?.title = region.regionName
		}

	}
	
	@IBAction func onRegions(_ sender: Any) {
		Router.Database.LocationPicker(mode: [.regions]) { [weak self] (controller, result) in
			controller.dismiss(animated: true, completion: nil)
			guard let region = result as? NCDBMapRegion else {return}
			self?.navigationItem.rightBarButtonItem?.title = region.regionName
			UserDefaults.standard.set(Int(region.regionID), forKey: UserDefaults.Key.NCMarketRegion)
			self?.treeController?.content = nil
			self?.reload()
			
			if let context = NCCache.sharedCache?.viewContext {
				let location: NCCacheLocationPickerRecent = context.fetch("LocationPickerRecent", where: "locationID == %d", region.regionID) ?? {
					let location = NCCacheLocationPickerRecent(entity: NSEntityDescription.entity(forEntityName: "LocationPickerRecent", in: context)!, insertInto: context)
					location.locationID = region.regionID
					location.locationType = NCCacheLocationPickerRecent.LocationType.region.rawValue
					return location
					}()
				location.date = Date()
				
				if context.hasChanges {
					try? context.save()
				}
			}
			
			
			NotificationCenter.default.post(name: .NCMarketRegionChanged, object: region)
		}.perform(source: self, sender: sender)
		

	}
	
	private var orders: NCCachedResult<[ESI.Market.Order]>?
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		let regionID = UserDefaults.standard.object(forKey: UserDefaults.Key.NCMarketRegion) as? Int ?? NCDBRegionID.theForge.rawValue
		
		dataManager.marketOrders(typeID: Int(type!.typeID), regionID: regionID) { result in
			self.orders = result
			completionHandler([result.cacheRecord].flatMap {$0})
		}
		
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = self.orders?.value {
			let locationIDs = value.map ({$0.locationID})
			
			dataManager.locations(ids: Set(locationIDs)) { locations in
				var buy: [ESI.Market.Order] = []
				var sell: [ESI.Market.Order] = []
				for order in value {
					if order.isBuyOrder {
						buy.append(order)
					}
					else {
						sell.append(order)
					}
				}
				buy.sort {return $0.price > $1.price}
				sell.sort {return $0.price < $1.price}
				
				let sellRows = sell.map { return NCDatabaseMarketInfoRow(order: $0, location: locations[$0.locationID])}
				let buyRows = buy.map { return NCDatabaseMarketInfoRow(order: $0, location: locations[$0.locationID])}
				let sections = [DefaultTreeSection(nodeIdentifier: "Sellers",
				                                   title: NSLocalizedString("Sellers", comment: "").uppercased(),
				                                   children: sellRows),
				                DefaultTreeSection(nodeIdentifier: "Buyers",
				                                   title: NSLocalizedString("Buyers", comment: "").uppercased(),
				                                   children: buyRows)]
				if sellRows.isEmpty && buyRows.isEmpty {
					self.tableView.backgroundView = NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: ""))
				}
				else {
					if self.treeController?.content == nil {
						self.treeController?.content = RootNode(sections)
					}
					else {
						self.treeController?.content?.children = sections
					}
					self.tableView.backgroundView = nil
				}
				completionHandler()
			}
		}
		else {
			self.tableView.backgroundView = treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: self.orders?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
}

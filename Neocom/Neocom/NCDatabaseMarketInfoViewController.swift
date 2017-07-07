//
//  NCDatabaseMarketInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

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

class NCDatabaseMarketInfoViewController: NCTreeViewController, NCRefreshable {
	var type: NCDBInvType?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
		registerRefreshable()
		
		let regionID = UserDefaults.standard.object(forKey: UserDefaults.Key.NCMarketRegion) as? Int ?? NCDBRegionID.theForge.rawValue
		if let region = NCDatabase.sharedDatabase?.mapRegions[regionID] {
			navigationItem.rightBarButtonItem?.title = region.regionName
		}

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController.content == nil {
			reload()
		}
	}
	
	@IBAction func unwindFromRegionPicker(segue: UIStoryboardSegue) {
		guard let controller = segue.source as? NCRegionPickerViewController else {return}
		guard let region = controller.region else {return}
		navigationItem.rightBarButtonItem?.title = region.regionName
		UserDefaults.standard.set(Int(region.regionID), forKey: UserDefaults.Key.NCMarketRegion)
		treeController.content = nil
		reload()
		
		NotificationCenter.default.post(name: .NCMarketRegionChanged, object: region)
	}
	
	//MARK: - NCRefreshable
	private var observer: NCManagedObjectObserver?
	private var orders: NCCachedResult<[ESI.Market.Order]>?
	private var locations: [Int64: NCLocation]?

	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		let dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		let regionID = UserDefaults.standard.object(forKey: UserDefaults.Key.NCMarketRegion) as? Int ?? NCDBRegionID.theForge.rawValue
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
		
		progress.progress.becomeCurrent(withPendingUnitCount: 1)
		dataManager.marketOrders(typeID: Int(type!.typeID), regionID: regionID) { result in
			self.orders = result
			
			switch result {
			case let .success(_, record):
				if let record = record {
					self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
						self?.reloadLocations(dataManager: dataManager) {
							self?.reloadSections()
							completionHandler?()
						}
					}
				}
				
				progress.progress.becomeCurrent(withPendingUnitCount: 1)
				self.reloadLocations(dataManager: dataManager) {
					self.reloadSections()
					completionHandler?()
					progress.finish()
				}
				progress.progress.resignCurrent()
			case .failure:
				completionHandler?()
				progress.finish()
			}
			
		}
		progress.progress.resignCurrent()
	}
	
	//MARK: Private
	
	private func reloadLocations(dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		guard let locationIDs = orders?.value?.map ({$0.locationID}), !locationIDs.isEmpty else {
			completionHandler?()
			return
		}
		dataManager.locations(ids: Set(locationIDs)) { [weak self] result in
			self?.locations = result
			completionHandler?()
		}
		
	}
	
	@objc private func refresh() {
		let progress = NCProgressHandler(totalUnitCount: 1)
		progress.progress.becomeCurrent(withPendingUnitCount: 1)
		reload(cachePolicy: .reloadIgnoringLocalCacheData) {
			self.refreshControl?.endRefreshing()
		}
		progress.progress.resignCurrent()
	}
	
	private func reloadSections() {
		if let value = orders?.value {
			let locations = self.locations ?? [:]
			
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
				if self.treeController.content == nil {
					let root = TreeNode()
					root.children = sections
					self.treeController.content = root
				}
				else {
					self.treeController.content?.children = sections
				}
				self.tableView.backgroundView = nil
			}

		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: orders?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}

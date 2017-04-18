//
//  NCDatabaseMarketInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 25.12.16.
//  Copyright © 2016 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCDatabaseMarketInfoRow: NCTreeRow {
	let price: String
	let location: NSAttributedString
	let quantity: String
	
	init(order: ESI.Market.Order, location: NCLocation?) {
		self.price = NCUnitFormatter.localizedString(from: order.price, unit: .isk, style: .full)
		self.location = location?.displayName ?? NSAttributedString(string: NSLocalizedString("Unknown location", comment: ""))
		self.quantity = NCUnitFormatter.localizedString(from: Double(order.volumeRemain), unit: .none, style: .full)
		super.init(cellIdentifier: "Cell")
	}
	
	override func configure(cell: UITableViewCell) {
		let cell = cell as! NCMarketInfoTableViewCell;
		cell.priceLabel.text = price
		cell.locationLabel.attributedText = location
		cell.quantityLabel.text = quantity
	}
}

class NCDatabaseMarketInfoViewController: UITableViewController, NCTreeControllerDelegate {
	var type: NCDBInvType?
	@IBOutlet weak var treeController: NCTreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		treeController.childrenKeyPath = "children"
		treeController.delegate = self
		refreshControl = UIRefreshControl()
		refreshControl?.addTarget(self, action: #selector(refresh), for: .valueChanged)
		
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
		treeController.reloadData()
		reload()
		NotificationCenter.default.post(name: .NCMarketRegionChanged, object: region)
	}
	
	//MARK: NCTreeControllerDelegate
	
	func treeController(_ treeController: NCTreeController, cellIdentifierForItem item: AnyObject) -> String {
		return (item as! NCTreeNode).cellIdentifier
	}
	
	func treeController(_ treeController: NCTreeController, configureCell cell: UITableViewCell, withItem item: AnyObject) {
		(item as! NCTreeNode).configure(cell: cell)
	}
	
	//MARK: Private
	
	@objc private func refresh() {
		let progress = NCProgressHandler(totalUnitCount: 1)
		progress.progress.becomeCurrent(withPendingUnitCount: 1)
		reload(cachePolicy: .reloadIgnoringLocalCacheData) {
			self.refreshControl?.endRefreshing()
		}
		progress.progress.resignCurrent()
	}
	
	private var observer: NCManagedObjectObserver?
	
	private func process(_ value: [ESI.Market.Order], dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		let locations = Set(value.map {return $0.locationID})
		
		dataManager.locations(ids: locations) { locations in
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
			let sections = [NCTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Sellers", title: NSLocalizedString("SELLERS", comment: ""), attributedTitle: nil, children: sellRows),
			                NCTreeSection(cellIdentifier: "NCHeaderTableViewCell", nodeIdentifier: "Buyers", title: NSLocalizedString("BUYERS", comment: ""), attributedTitle: nil, children: buyRows)]
			if sellRows.isEmpty && buyRows.isEmpty {
				self.tableView.backgroundView = NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: ""))
			}
			else {
				self.treeController.content = sections
				self.tableView.backgroundView = nil
				self.treeController.reloadData()
			}
			completionHandler?()

		}
	}
	
	private func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		let dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		let regionID = UserDefaults.standard.object(forKey: UserDefaults.Key.NCMarketRegion) as? Int ?? NCDBRegionID.theForge.rawValue
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
		
		progress.progress.becomeCurrent(withPendingUnitCount: 1)
		dataManager.marketOrders(typeID: Int(type!.typeID), regionID: regionID) { result in
			switch result {
			case let .success(value, cacheRecord):
				if let cacheRecord = cacheRecord {
					self.observer = NCManagedObjectObserver(managedObject: cacheRecord) { [weak self] _, _ in
						guard let value = cacheRecord.data?.data as? [ESI.Market.Order] else {return}
						self?.process(value, dataManager: dataManager, completionHandler: nil)
					}
				}
				progress.progress.becomeCurrent(withPendingUnitCount: 1)
				self.process(value, dataManager: dataManager) {
					progress.finish()
					completionHandler?()
				}
				progress.progress.resignCurrent()
			case let .failure(error):
				if self.treeController.content == nil {
					self.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
				}
				progress.finish()
				completionHandler?()
			}
		}
		progress.progress.resignCurrent()
	}
}

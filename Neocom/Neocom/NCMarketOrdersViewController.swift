//
//  NCMarketOrdersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCMarketOrdersViewController: NCTreeViewController {
	var owner = Owner.character

	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload
		tableView.register([Prototype.NCHeaderTableViewCell.default])
	}
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		switch owner {
		case .character:
			return dataManager.marketOrders().then(on: .main) { result -> [NCCacheRecord] in
				self.orders = result
				return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
			}
		case .corporation:
			return dataManager.corpMarketOrders().then(on: .main) { result -> [NCCacheRecord] in
				self.corpOrders = result
				return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
			}
		}
	}
	
	override func content() -> Future<TreeNode?> {
		let orders = self.orders
		let corpOrders = self.corpOrders
		let progress = Progress(totalUnitCount: 3)
		
		return DispatchQueue.global(qos: .utility).async { () -> TreeNode? in
			guard let value: [NCMarketOrder] = orders?.value ?? corpOrders?.value else {throw NCTreeViewControllerError.noResult}
			let locationIDs = Set(value.map {$0.locationID})
			let locations = try? progress.perform{ self.dataManager.locations(ids: locationIDs) }.get()
			
			return try NCDatabase.sharedDatabase!.performTaskAndWait { managedObjectContext in
				
				let open = value
				
				var buy = open.filter {$0.isBuyOrder == true}.map {NCMarketOrderRow(order: $0, location: locations?[$0.locationID])}
				var sell = open.filter {$0.isBuyOrder != true}.map {NCMarketOrderRow(order: $0, location: locations?[$0.locationID])}
				
				buy.sort {$0.expired < $1.expired}
				sell.sort {$0.expired < $1.expired}
				
				var sections = [TreeNode]()
				
				if !sell.isEmpty {
					sections.append(DefaultTreeSection(nodeIdentifier: "Sell", title: NSLocalizedString("Sell", comment: "").uppercased(), children: sell))
				}
				if !buy.isEmpty {
					sections.append(DefaultTreeSection(nodeIdentifier: "Buy", title: NSLocalizedString("Buy", comment: "").uppercased(), children: buy))
				}
				guard !sections.isEmpty else {throw NCTreeViewControllerError.noResult}
				return RootNode(sections)
			}
		}
	}
	
	private var orders: CachedValue<[ESI.Market.CharacterOrder]>?
	private var corpOrders: CachedValue<[ESI.Market.CorpOrder]>?
	
}

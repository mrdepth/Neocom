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
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		switch owner {
		case .character:
			dataManager.marketOrders().then(on: .main) { result in
				self.orders = result
				completionHandler([result.cacheRecord].flatMap {$0})
			}.catch(on: .main) { error in
				self.error = error
				completionHandler([])
			}
		case .corporation:
			dataManager.corpMarketOrders().then(on: .main) { result in
				self.corpOrders = result
				completionHandler([result.cacheRecord].flatMap {$0})
			}.catch(on: .main) { error in
				self.error = error
				completionHandler([])
			}
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		let orders = self.orders
		let corpOrders = self.corpOrders
		let progress = Progress(totalUnitCount: 3)
		
		OperationQueue(qos: .utility).async { () -> [TreeNode] in
			guard let value: [NCMarketOrder] = orders?.value ?? corpOrders?.value else {return []}
			let locationIDs = Set(value.map {$0.locationID})
			let locations = try? progress.perform{ self.dataManager.locations(ids: locationIDs) }.get()
			
			return NCDatabase.sharedDatabase!.performTaskAndWait { managedObjectContext in
				
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
				return sections
			}
		}.then(on: .main) { sections in
			if self.treeController?.content == nil {
				self.treeController?.content = RootNode(sections)
			}
			else {
				self.treeController?.content?.children = sections
			}
		}.catch(on: .main) {error in
			self.error = error
		}.finally(on: .main) {
			self.tableView.backgroundView = self.treeController?.content?.children.isEmpty == false ? nil : NCTableViewBackgroundLabel(text: self.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var orders: CachedValue<[ESI.Market.CharacterOrder]>?
	private var corpOrders: CachedValue<[ESI.Market.CorpOrder]>?
	private var error: Error?
	
}

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
	
	override func viewDidLoad() {
		super.viewDidLoad()
		needsReloadOnAccountChange = true
		tableView.register([Prototype.NCHeaderTableViewCell.default])
	}
	
	override func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void) {
		dataManager.marketOrders { result in
			self.orders = result
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}
	
	override func updateContent(completionHandler: @escaping () -> Void) {
		if let value = orders?.value {
			tableView.backgroundView = nil
			
			let locationIDs = Set(value.map {$0.locationID})
			
			dataManager.locations(ids: locationIDs) { locations in
				NCDatabase.sharedDatabase?.performBackgroundTask { managedObjectContext in
					
					let open = value.filter {$0.state == .open}
					
					var buy = open.filter {$0.isBuyOrder}.map {NCMarketOrderRow(order: $0, location: locations[$0.locationID])}
					var sell = open.filter {!$0.isBuyOrder}.map {NCMarketOrderRow(order: $0, location: locations[$0.locationID])}
					var closed = value.filter {$0.state != .open}.map {NCMarketOrderRow(order: $0, location: locations[$0.locationID])}
					
					buy.sort {$0.expired < $1.expired}
					sell.sort {$0.expired < $1.expired}
					closed.sort {$0.expired > $1.expired}
					
					var sections = [TreeNode]()
					
					if !sell.isEmpty {
						sections.append(DefaultTreeSection(nodeIdentifier: "Sell", title: NSLocalizedString("Sell", comment: "").uppercased(), children: sell))
					}
					if !buy.isEmpty {
						sections.append(DefaultTreeSection(nodeIdentifier: "Buy", title: NSLocalizedString("Buy", comment: "").uppercased(), children: buy))
					}
					if !closed.isEmpty {
						sections.append(DefaultTreeSection(nodeIdentifier: "Closed", title: NSLocalizedString("Closed", comment: "").uppercased(), children: closed))
					}
					
					
					DispatchQueue.main.async {
						
						if self.treeController?.content == nil {
							self.treeController?.content = RootNode(sections)
						}
						else {
							self.treeController?.content?.children = sections
						}
						self.tableView.backgroundView = sections.isEmpty ? NCTableViewBackgroundLabel(text: NSLocalizedString("No Results", comment: "")) : nil
						completionHandler()

					}
				}
			}
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: orders?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
			completionHandler()
		}
	}
	
	private var orders: NCCachedResult<[ESI.Market.CharacterOrder]>?
	
}

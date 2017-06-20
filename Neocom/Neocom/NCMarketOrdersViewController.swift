//
//  NCMarketOrdersViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCMarketOrdersViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCHeaderTableViewCell.default])
		
		registerRefreshable()
		
		treeController.delegate = self
		
		reload()
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let row = node as? TreeNodeRoutable {
			row.route?.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	//MARK: - NCRefreshable
	
	private var observer: NCManagedObjectObserver?
	private var orders: NCCachedResult<[ESI.Market.CharacterOrder]>?
	private var locations: [Int64: NCLocation]?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 1)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		progress.perform {
			dataManager.marketOrders { result in
				self.orders = result
				
				switch result {
				case let .success(_, record):
					if let record = record {
						self.observer = NCManagedObjectObserver(managedObject: record) { [weak self] _ in
							self?.reloadLocations(dataManager: dataManager) {
								self?.reloadSections()
							}
						}
					}
					
					self.reloadLocations(dataManager: dataManager) {
						self.reloadSections()
						completionHandler?()
					}
				case .failure:
					self.reloadSections()
					completionHandler?()
				}
				
				
			}
		}
	}
	
	private func reloadLocations(dataManager: NCDataManager, completionHandler: (() -> Void)?) {
		guard let value = orders?.value else {
			completionHandler?()
			return
		}
		let locationIDs = Set(value.map {$0.locationID})
		
		guard !locationIDs.isEmpty else {
			completionHandler?()
			return
		}
		
		dataManager.locations(ids: locationIDs) { [weak self] result in
			self?.locations = result
			completionHandler?()
		}
	}
	
	private func reloadSections() {
		if let value = orders?.value {
			tableView.backgroundView = nil
			let locations = self.locations ?? [:]
			
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
			}
			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: orders?.error?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}

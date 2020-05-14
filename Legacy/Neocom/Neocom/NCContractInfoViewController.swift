//
//  NCContractInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CoreData
import Futures

class NCContractContactRow: NCContactRow {
	let title: String
	
	init(title: String , contact: NSManagedObjectID?, dataManager: NCDataManager) {
		self.title = title
		super.init(prototype: Prototype.NCContactTableViewCell.attribute, contact: contact, dataManager: dataManager)
	}

	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = title
		cell.subtitleLabel?.text = contact?.name
		cell.accessoryType = .none
	}
}

class NCContractItem: TreeRow {
	let item: ESI.Contracts.Item
	
	lazy var type: NCDBInvType? = {
		return NCDatabase.sharedDatabase?.invTypes[self.item.typeID]
	}()
	
	init(item: ESI.Contracts.Item) {
		self.item = item
		super.init(prototype: Prototype.NCDefaultTableViewCell.default, route: Router.Database.TypeInfo(item.typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.subtitleLabel?.text = NSLocalizedString("Quantity", comment: "") + ": " + NCUnitFormatter.localizedString(from: item.quantity, unit: .none, style: .full)
		cell.accessoryType = .disclosureIndicator
	}
	
	override var hash: Int {
		return item.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCContractItem)?.hashValue == hashValue
	}
}

class NCContractBidRow: NCContactRow {
	let bid: ESI.Contracts.Bid
	init(bid: ESI.Contracts.Bid , contact: NSManagedObjectID?, dataManager: NCDataManager) {
		self.bid = bid
		super.init(prototype: Prototype.NCContactTableViewCell.default, contact: contact, dataManager: dataManager)
	}
	
	override func configure(cell: UITableViewCell) {
		super.configure(cell: cell)
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = NCUnitFormatter.localizedString(from: bid.amount, unit: .isk, style: .full)
		cell.subtitleLabel?.text = contact?.name
		cell.accessoryType = .none
	}
}

class NCContractInfoViewController: NCTreeViewController {
	
	var contract: ESI.Contracts.Contract?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.attributeNoImage,
		                    Prototype.NCContactTableViewCell.attribute,
		                    Prototype.NCContactTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])
	}
	
	
	override func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		guard NCAccount.current != nil, let contract = contract else {
			return .init(.failure(NCTreeViewControllerError.noResult))
		}
		
		let progress = Progress(totalUnitCount: 2)
		
		return DispatchQueue.global(qos: .utility).async { () -> (CachedValue<[ESI.Contracts.Item]>, CachedValue<[ESI.Contracts.Bid]>) in
			let items = try progress.perform { self.dataManager.contractItems(contractID: Int64(contract.contractID))}.get()
			let bids = try progress.perform { self.dataManager.contractBids(contractID: Int64(contract.contractID))}.get()
			return (items, bids)
		}.then(on: .main) { (items, bids) -> [NCCacheRecord] in
			self.items = items
			self.bids = bids
			return [items.cacheRecord(in: NCCache.sharedCache!.viewContext), bids.cacheRecord(in: NCCache.sharedCache!.viewContext)]
		}
	}
	
	override func content() -> Future<TreeNode?> {
		let progress = Progress(totalUnitCount: 2)
		
		return DispatchQueue.global(qos: .utility).async { () -> ([Int64: NSManagedObjectID]?, [Int64: NCLocation]?) in
			guard let contract = self.contract else {return (nil, nil)}
			
			let contacts = progress.perform { () -> [Int64: NSManagedObjectID]? in
				var contactIDs = Set<Int64>()
				if contract.acceptorID > 0 {
					contactIDs.insert(Int64(contract.acceptorID))
				}
				if contract.assigneeID > 0 {
					contactIDs.insert(Int64(contract.assigneeID))
				}
				if contract.issuerID > 0 {
					contactIDs.insert(Int64(contract.issuerID))
				}
				
				if let bids = self.bids?.value {
					contactIDs.formUnion(bids.map{Int64($0.bidderID)})
				}
				
				return try? self.dataManager.contacts(ids: contactIDs).get()
			}
			
			let locations = progress.perform { () -> [Int64: NCLocation]? in
				var locationIDs = Set<Int64>()
				if let locationID = contract.startLocationID {
					locationIDs.insert(locationID)
				}
				if let locationID = contract.endLocationID {
					locationIDs.insert(locationID)
				}
				
				return try? self.dataManager.locations(ids: locationIDs).get()
			}
			
			return (contacts, locations)
		}.then(on: .main) { (contacts, locations) -> TreeNode? in
			guard let contract = self.contract else {throw NCTreeViewControllerError.noResult}

			var sections = [TreeNode]()
			var rows = [TreeNode]()
			
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
									   nodeIdentifier: "Type",
									   title: NSLocalizedString("Type", comment: "").uppercased(),
									   subtitle: contract.type.title))
			
			if let description = contract.title, !description.isEmpty {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
										   nodeIdentifier: "Description",
										   title: NSLocalizedString("Description", comment: "").uppercased(),
										   subtitle: description))
			}
			
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
									   nodeIdentifier: "Availability",
									   title: NSLocalizedString("Availability", comment: "").uppercased(),
									   subtitle: contract.availability.title))
			
			let status = contract.currentStatus
			
			
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
									   nodeIdentifier: "Status",
									   title: NSLocalizedString("Status", comment: "").uppercased(),
									   subtitle: status.title))
			
			if let contact = contacts?[Int64(contract.issuerID)] {
				rows.append(NCContractContactRow(title: NSLocalizedString("From", comment: "").uppercased(), contact: contact, dataManager: self.dataManager))
			}
			if let contact = contacts?[Int64(contract.assigneeID)] {
				rows.append(NCContractContactRow(title: NSLocalizedString("To", comment: "").uppercased(), contact: contact, dataManager: self.dataManager))
			}
			if let contact = contacts?[Int64(contract.acceptorID)] {
				rows.append(NCContractContactRow(title: NSLocalizedString("Acceptor", comment: "").uppercased(), contact: contact, dataManager: self.dataManager))
			}
			
			
			if let fromID = contract.startLocationID, let toID = contract.endLocationID, fromID != toID, let from = locations?[fromID], let to = locations?[toID] {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
										   nodeIdentifier: "StartLocation",
										   title: NSLocalizedString("Start Location", comment: "").uppercased(),
										   attributedSubtitle: from.displayName))
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
										   nodeIdentifier: "EndLocation",
										   title: NSLocalizedString("End Location", comment: "").uppercased(),
										   attributedSubtitle: to.displayName))
			}
			else if let locationID = contract.startLocationID, let location = locations?[locationID] {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
										   nodeIdentifier: "Location",
										   title: NSLocalizedString("Location", comment: "").uppercased(),
										   attributedSubtitle: location.displayName))
			}
			
			if let price = contract.price, price > 0 {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
										   nodeIdentifier: "Price",
										   title: NSLocalizedString("Buyer Will Pay", comment: "").uppercased(),
										   subtitle: NCUnitFormatter.localizedString(from: price, unit: .isk, style: .full)))
			}
			
			if let reward = contract.reward, reward > 0 {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
										   nodeIdentifier: "Reward",
										   title: NSLocalizedString("Buyer Will Get", comment: "").uppercased(),
										   subtitle: NCUnitFormatter.localizedString(from: reward, unit: .isk, style: .full)))
			}
			
			
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
									   nodeIdentifier: "Issued",
									   title: NSLocalizedString("Date Issued", comment: "").uppercased(),
									   subtitle: DateFormatter.localizedString(from: contract.dateIssued, dateStyle: .medium, timeStyle: .medium)))
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
									   nodeIdentifier: "Expired",
									   title: NSLocalizedString("Date Expired", comment: "").uppercased(),
									   subtitle: DateFormatter.localizedString(from: contract.dateExpired, dateStyle: .medium, timeStyle: .medium)))
			
			if let date = contract.dateAccepted {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
										   nodeIdentifier: "Accepted",
										   title: NSLocalizedString("Date Accepted", comment: "").uppercased(),
										   subtitle: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)))
			}
			if let date = contract.dateCompleted {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.attributeNoImage,
										   nodeIdentifier: "Completed",
										   title: NSLocalizedString("Date Completed", comment: "").uppercased(),
										   subtitle: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)))
			}
			
			sections.append(DefaultTreeSection(nodeIdentifier: "Details",
											   title: NSLocalizedString("Details", comment: "").uppercased(),
											   children: rows))
			
			if let items = self.items?.value, !items.isEmpty {
				let get = items.filter {$0.isIncluded}.map ({NCContractItem(item: $0)})
				let pay = items.filter {!$0.isIncluded}.map ({NCContractItem(item: $0)})
				if !get.isEmpty {
					sections.append(DefaultTreeSection(nodeIdentifier: "BuyerWillGet",
													   title: NSLocalizedString("Buyer Will Get", comment: "").uppercased(),
													   children: get))
				}
				if !pay.isEmpty {
					sections.append(DefaultTreeSection(nodeIdentifier: "BuyerWillPay",
													   title: NSLocalizedString("Buyer Will Pay", comment: "").uppercased(),
													   children: pay))
				}
			}
			
			if let bids = self.bids?.value, !bids.isEmpty {
				let rows = bids.sorted {$0.amount > $1.amount}.map {NCContractBidRow(bid: $0, contact: contacts?[Int64($0.bidderID)], dataManager: self.dataManager)}
				sections.append(DefaultTreeSection(nodeIdentifier: "Bids",
												   title: NSLocalizedString("Bids", comment: "").uppercased(),
												   children: rows))
			}
			guard !sections.isEmpty else {throw NCTreeViewControllerError.noResult}
			return RootNode(sections)
		}
	}
	
	private var items: CachedValue<[ESI.Contracts.Item]>?
	private var bids: CachedValue<[ESI.Contracts.Bid]>?
}

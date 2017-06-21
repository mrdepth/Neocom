//
//  NCContractInfoViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

class NCContractContactRow: NCContactRow {
	let title: String
	
	init(title: String , contact: NCContact?, dataManager: NCDataManager) {
		self.title = title
		super.init(prototype: Prototype.NCContactTableViewCell.default, contact: contact, dataManager: dataManager)
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
		super.init(prototype: Prototype.NCContactTableViewCell.default, route: Router.Database.TypeInfo(item.typeID))
	}
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCDefaultTableViewCell else {return}
		cell.titleLabel?.text = type?.typeName
		cell.iconView?.image = type?.icon?.image?.image ?? NCDBEveIcon.defaultType.image?.image
		cell.subtitleLabel?.text = NSLocalizedString("Quantity", comment: "") + ": " + NCUnitFormatter.localizedString(from: item.quantity, unit: .none, style: .full)
		cell.accessoryType = .disclosureIndicator
	}
	
	override var hashValue: Int {
		return item.hashValue
	}
	
	override func isEqual(_ object: Any?) -> Bool {
		return (object as? NCContractItem)?.hashValue == hashValue
	}
}

class NCContractBidRow: NCContactRow {
	let bid: ESI.Contracts.Bid
	init(bid: ESI.Contracts.Bid , contact: NCContact?, dataManager: NCDataManager) {
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

class NCContractInfoViewController: UITableViewController, TreeControllerDelegate, NCRefreshable {
	
	@IBOutlet var treeController: TreeController!
	
	var contract: ESI.Contracts.Contract?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		tableView.register([Prototype.NCDefaultTableViewCell.default,
		                    Prototype.NCDefaultTableViewCell.noImage,
		                    Prototype.NCContactTableViewCell.default,
		                    Prototype.NCHeaderTableViewCell.default])
		
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
	private var items: NCCachedResult<[ESI.Contracts.Item]>?
	private var bids: NCCachedResult<[ESI.Contracts.Bid]>?
	private var locations: [Int64: NCLocation]?
	private var contacts: [Int64: NCContact]?
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: (() -> Void)?) {
		guard let account = NCAccount.current, let contract = contract else {
			completionHandler?()
			return
		}
		
		let progress = Progress(totalUnitCount: 4)
		
		let dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		
		let dispatchGroup = DispatchGroup()
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.contractItems(contractID: Int64(contract.contractID)) { result in
				self.items = result
				dispatchGroup.leave()
			}
		}
		
		progress.perform {
			dispatchGroup.enter()
			dataManager.contractBids(contractID: Int64(contract.contractID)) { result in
				self.bids = result
				
				progress.perform {
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
					
					if let bids = result.value {
						contactIDs.formUnion(bids.map{Int64($0.bidderID)})
					}
					
					if !contactIDs.isEmpty {
						dispatchGroup.enter()
						dataManager.contacts(ids: contactIDs) { result in
							self.contacts = result
							dispatchGroup.leave()
						}
					}
				}

				
				dispatchGroup.leave()
			}
		}
		
		progress.perform {
			var locationIDs = Set<Int64>()
			if let locationID = contract.startLocationID {
				locationIDs.insert(locationID)
			}
			if let locationID = contract.endLocationID {
				locationIDs.insert(locationID)
			}
			
			if !locationIDs.isEmpty {
				dispatchGroup.enter()
				dataManager.locations(ids: locationIDs) { result in
					self.locations = result
					dispatchGroup.leave()
				}
			}
		}
		
		dispatchGroup.notify(queue: .main) {
			self.reloadSections()
			completionHandler?()
		}
	}

	private func reloadSections() {
		if let contract = self.contract {
			tableView.backgroundView = nil
			let locations = self.locations ?? [:]
			let contacts = self.contacts
			
			let dataManager = NCDataManager(account: NCAccount.current)
			
			var sections = [TreeNode]()
			var rows = [TreeNode]()
			
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
			                           nodeIdentifier: "Type",
			                           title: NSLocalizedString("Type", comment: ""),
			                           subtitle: contract.type.title))
			
			if let description = contract.title, !description.isEmpty {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
				                           nodeIdentifier: "Description",
				                           title: NSLocalizedString("Description", comment: ""),
				                           subtitle: description))
			}

			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
			                           nodeIdentifier: "Availability",
			                           title: NSLocalizedString("Availability", comment: ""),
			                           subtitle: contract.availability.title))

			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
			                           nodeIdentifier: "Status",
			                           title: NSLocalizedString("Status", comment: ""),
			                           subtitle: contract.status.title))
			
			if let contact = contacts?[Int64(contract.issuerID)] {
				rows.append(NCContractContactRow(title: NSLocalizedString("From", comment: ""), contact: contact, dataManager: dataManager))
			}
			if let contact = contacts?[Int64(contract.assigneeID)] {
				rows.append(NCContractContactRow(title: NSLocalizedString("To", comment: ""), contact: contact, dataManager: dataManager))
			}
			if let contact = contacts?[Int64(contract.acceptorID)] {
				rows.append(NCContractContactRow(title: NSLocalizedString("Acceptor", comment: ""), contact: contact, dataManager: dataManager))
			}

			
			if let fromID = contract.startLocationID, let toID = contract.endLocationID, fromID != toID, let from = locations[fromID], let to = locations[toID] {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
				                           nodeIdentifier: "StartLocation",
				                           title: NSLocalizedString("Start Location", comment: ""),
				                           attributedSubtitle: from.displayName))
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
				                           nodeIdentifier: "EndLocation",
				                           title: NSLocalizedString("End Location", comment: ""),
				                           attributedSubtitle: to.displayName))
			}
			else if let locationID = contract.startLocationID, let location = locations[locationID] {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
				                           nodeIdentifier: "Location",
				                           title: NSLocalizedString("Location", comment: ""),
				                           attributedSubtitle: location.displayName))
			}
			
			if let price = contract.price, price > 0 {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
				                           nodeIdentifier: "Price",
				                           title: NSLocalizedString("Buyer Will Pay", comment: ""),
				                           subtitle: NCUnitFormatter.localizedString(from: price, unit: .isk, style: .full)))
			}

			if let reward = contract.reward, reward > 0 {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
				                           nodeIdentifier: "Reward",
				                           title: NSLocalizedString("Buyer Will Get", comment: ""),
				                           subtitle: NCUnitFormatter.localizedString(from: reward, unit: .isk, style: .full)))
			}
			

			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
			                           nodeIdentifier: "Issued",
			                           title: NSLocalizedString("Date Issued", comment: ""),
			                           subtitle: DateFormatter.localizedString(from: contract.dateIssued, dateStyle: .medium, timeStyle: .medium)))
			rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
			                           nodeIdentifier: "Expired",
			                           title: NSLocalizedString("Date Expired", comment: ""),
			                           subtitle: DateFormatter.localizedString(from: contract.dateExpired, dateStyle: .medium, timeStyle: .medium)))
			
			if let date = contract.dateAccepted {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
				                           nodeIdentifier: "Accepted",
				                           title: NSLocalizedString("Date Accepted", comment: ""),
				                           subtitle: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)))
			}
			if let date = contract.dateCompleted {
				rows.append(DefaultTreeRow(prototype: Prototype.NCDefaultTableViewCell.noImage,
				                           nodeIdentifier: "Completed",
				                           title: NSLocalizedString("Date Completed", comment: ""),
				                           subtitle: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)))
			}
			
			sections.append(DefaultTreeSection(nodeIdentifier: "Info",
			                                   title: NSLocalizedString("Info", comment: "").uppercased(),
			                                   children: rows))

			if let items = items?.value, !items.isEmpty {
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
			
			if let bids = bids?.value, !bids.isEmpty {
				let rows = bids.sorted {$0.amount > $1.amount}.map {NCContractBidRow(bid: $0, contact: contacts?[Int64($0.bidderID)], dataManager: dataManager)}
				sections.append(DefaultTreeSection(nodeIdentifier: "Bids",
				                                   title: NSLocalizedString("Bids", comment: "").uppercased(),
				                                   children: rows))
			}
			
			if self.treeController.content == nil {
				let root = TreeNode()
				root.children = sections
				self.treeController.content = root
			}
			else {
				self.treeController.content?.children = sections
			}

			
		}
		else {
			tableView.backgroundView = NCTableViewBackgroundLabel(text: (items?.error ?? bids?.error)?.localizedDescription ?? NSLocalizedString("No Result", comment: ""))
		}
	}
	
}

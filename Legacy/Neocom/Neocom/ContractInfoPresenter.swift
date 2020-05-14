//
//  ContractInfoPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/12/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import EVEAPI

class ContractInfoPresenter: TreePresenter {
	typealias View = ContractInfoViewController
	typealias Interactor = ContractInfoInteractor
	typealias Presentation = [AnyTreeItem]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeSectionCell.default,
								  Prototype.TreeDefaultCell.default,
								  Prototype.TreeDefaultCell.attribute,
								  Prototype.TreeDefaultCell.contact])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		var rows = [Tree.Item.Row<Tree.Content.Default>]()
		let contract = content.value.contract
		let contacts = content.value.contacts
		let locations = content.value.locations
		let api = interactor.api
		
		rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
													   title: NSLocalizedString("Type", comment: "").uppercased(),
													   subtitle: contract.type.title),
								  diffIdentifier: "Type"))
		
		if let description = contract.title, !description.isEmpty {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Description", comment: "").uppercased(),
														   subtitle: description),
									  diffIdentifier: "Description"))
		}
		
		rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
													   title: NSLocalizedString("Availability", comment: "").uppercased(),
													   subtitle: contract.availability.title),
								  diffIdentifier: "Availability"))

		rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
													   title: NSLocalizedString("Status", comment: "").uppercased(),
													   subtitle: contract.currentStatus.title),
								  diffIdentifier: "Status"))

		if let fromID = contract.startLocationID, let toID = contract.endLocationID, fromID != toID, let from = locations?[fromID], let to = locations?[toID] {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Start Location", comment: "").uppercased(),
														   attributedSubtitle: from.displayName),
									  diffIdentifier: "StartLocation"))

			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("End Location", comment: "").uppercased(),
														   attributedSubtitle: to.displayName),
									  diffIdentifier: "EndLocation"))
		}
		else if let locationID = contract.startLocationID, let location = locations?[locationID] {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Location", comment: "").uppercased(),
														   attributedSubtitle: location.displayName),
									  diffIdentifier: "Location"))
		}
		
		if let price = contract.price, price > 0 {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Buyer Will Pay", comment: "").uppercased(),
														   subtitle: UnitFormatter.localizedString(from: price, unit: .isk, style: .long)),
									  diffIdentifier: "Price"))
		}
		
		if let reward = contract.reward, reward > 0 {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Buyer Will Get", comment: "").uppercased(),
														   subtitle: UnitFormatter.localizedString(from: reward, unit: .isk, style: .long)),
									  diffIdentifier: "Reward"))
		}
		
		rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
													   title: NSLocalizedString("Date Issued", comment: "").uppercased(),
													   subtitle: DateFormatter.localizedString(from: contract.dateIssued, dateStyle: .medium, timeStyle: .medium)),
								  diffIdentifier: "Issued"))

		rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
													   title: NSLocalizedString("Date Expired", comment: "").uppercased(),
													   subtitle: DateFormatter.localizedString(from: contract.dateExpired, dateStyle: .medium, timeStyle: .medium)),
								  diffIdentifier: "Expired"))

		if let date = contract.dateAccepted {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Date Accepted", comment: "").uppercased(),
														   subtitle: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)),
									  diffIdentifier: "Accepted"))
		}

		if let date = contract.dateCompleted {
			rows.append(Tree.Item.Row(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.attribute,
														   title: NSLocalizedString("Date Completed", comment: "").uppercased(),
														   subtitle: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .medium)),
									  diffIdentifier: "Completed"))
		}
		
		var sections = [Tree.Item.SimpleSection(title: NSLocalizedString("Details", comment: "").uppercased(), treeController: view?.treeController, children: rows).asAnyItem]
		
		if let items = content.value.items, !items.isEmpty {
			
			let context = Services.sde.viewContext
			func makeRow(_ item: ESI.Contracts.Item) -> Tree.Item.Row<Tree.Content.Default> {
				let type = context.invType(item.typeID)
				return Tree.Item.RoutableRow(Tree.Content.Default(title: type?.typeName ?? NSLocalizedString("Unknown", comment: ""),
																  subtitle: String.localizedStringWithFormat(NSLocalizedString("Quantity: %@", comment: ""), UnitFormatter.localizedString(from: item.quantity, unit: .none, style: .long)),
																  image: Image(type?.icon ?? context.eveIcon(.defaultType)),
																  accessoryType: .disclosureIndicator),
											 diffIdentifier: item,
											 route: type.map{Router.SDE.invTypeInfo(.type($0))})
			}
			
			let get = items.filter{$0.isIncluded}.map{makeRow($0)}
			let pay = items.filter{!$0.isIncluded}.map{makeRow($0)}
			
			if !get.isEmpty {
				sections.append(Tree.Item.SimpleSection(title: NSLocalizedString("Buyer Will Get", comment: "").uppercased(), treeController: view?.treeController, children: get).asAnyItem)
			}
			if !pay.isEmpty {
				sections.append(Tree.Item.SimpleSection(title: NSLocalizedString("Buyer Will Pay", comment: "").uppercased(), treeController: view?.treeController, children: pay).asAnyItem)
			}
		}
		
		if let bids = content.value.bids, !bids.isEmpty {
			let rows = bids.sorted {$0.amount > $1.amount}.map {
				Tree.Item.BidRow($0, contact: contacts?[Int64($0.bidderID)], api: api)
			}
			
			if !rows.isEmpty {
				sections.append(Tree.Item.SimpleSection(title: NSLocalizedString("Bids", comment: "").uppercased(), treeController: view?.treeController, children: rows).asAnyItem)
			}
		}

		return .init(sections)
	}
}

extension Tree.Item {
	class BidRow: Row<ESI.Contracts.Bid> {
		var api: API
		var contact: Contact?
		
		init(_ content: ESI.Contracts.Bid, contact: Contact?, api: API) {
			self.api = api
			super.init(content)
		}
		
		override var prototype: Prototype? {
			return contact?.recipientType == .character ? Prototype.TreeDefaultCell.contact : Prototype.TreeDefaultCell.default
		}
		
		var image: UIImage?
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? TreeDefaultCell else {return}
			cell.titleLabel?.text = UnitFormatter.localizedString(from: content.amount, unit: .isk, style: .long)
			
			cell.subtitleLabel?.text = contact?.name
			cell.subtitleLabel?.isHidden = false
			
			cell.iconView?.isHidden = false
			cell.iconView?.image = image ?? UIImage()
			
			if let contact = contact, image == nil {
				let dimension = Int(cell.iconView!.bounds.width)
				
				api.image(contact: contact, dimension: dimension, cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self, weak treeController] result in
					guard let strongSelf = self else {return}
					strongSelf.image = result.value
					treeController?.reloadRow(for: strongSelf, with: .none)
				}.catch(on: .main) { [weak self] _ in
					self?.image = UIImage()
				}
			}
		}
	}
}

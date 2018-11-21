//
//  ZKillboardPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/15/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import CoreData

class ZKillboardPresenter: TreePresenter {
	typealias View = ZKillboardViewController
	typealias Interactor = ZKillboardInteractor
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
								  Prototype.TreeDefaultCell.attribute,
								  Prototype.TreeDefaultCell.action,
								  Prototype.TreeDefaultCell.contact,
								  Prototype.TreeDefaultCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	struct Filter {
		var from: Date?
		var to: Date?
		var pilot: Contact?
		var location: MapLocationPicker.View.Location?
		var ship: ZKillboardTypePicker.View.Result?
	}
	
	var filter = Filter()
	
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		let result = [pilotRow,
					  shipRow,
					  locationRow,
					  fromRow,
					  toRow]
		
		return .init([Tree.Item.Virtual(children: result, diffIdentifier: 0).asAnyItem])
	}
	
	private var pilotRow: AnyTreeItem {
		let route = Router.KillReports.contacts(Contacts.View.Input { [weak self] (controller, contact) in
			guard let strongSelf = self, let view = strongSelf.view else {return}
			controller.unwinder?.unwind(to: view)
			strongSelf.filter.pilot = contact
			strongSelf.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { view.present($0, animated: true)}
		})
		
		if let contact = filter.pilot {
			return Tree.Item.ZKillboardContactRow(contact, api: interactor.api, route: route) { [weak self] (_) in
				self?.filter.pilot = nil
				self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
			}.asAnyItem
		}
		else {
			return Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.action,
																 title: NSLocalizedString("Pilot", comment: "").uppercased()),
											diffIdentifier: "Pilot",
											route: route).asAnyItem
		}
	}
	
	private var shipRow: AnyTreeItem {
		let route = Router.KillReports.typePicker { [weak self] (controller, result) in
			guard let strongSelf = self, let view = strongSelf.view else {return}
			controller.unwinder?.unwind(to: view)
			strongSelf.filter.ship = result
			strongSelf.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { view.present($0, animated: true)}
		}
		
		if let ship = filter.ship {
			switch ship {
			case let .type(type):
				return Tree.Item.RoutableRow(Tree.Content.Default(title: type.typeName,
																  image: Image(type.icon ?? Services.sde.viewContext.eveIcon(.defaultType)),
																  accessoryType: .imageButton(Image(#imageLiteral(resourceName: "clear.pdf")), { [weak self] _ in
																	self?.filter.ship = nil
																	self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
																})),
											 diffIdentifier: type,
											 route: route).asAnyItem
			case let .group(group):
				return Tree.Item.RoutableRow(Tree.Content.Default(title: group.groupName,
																  image: Image(group.icon ?? Services.sde.viewContext.eveIcon(.defaultGroup)),
																  accessoryType: .imageButton(Image(#imageLiteral(resourceName: "clear.pdf")), { [weak self] _ in
																	self?.filter.ship = nil
																	self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
																})),
											 diffIdentifier: group,
											 route: route).asAnyItem
			}
		}
		else {
			return Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.action,
															  title: NSLocalizedString("Ship", comment: "").uppercased()),
										 diffIdentifier: "Ship",
										 route: route).asAnyItem
		}
	}
	
	private var locationRow: AnyTreeItem {
		let route = Router.SDE.mapLocationPicker(MapLocationPicker.View.Input(mode: .all) { [weak self] (controller, location) in
			guard let strongSelf = self, let view = strongSelf.view else {return}
			strongSelf.filter.location = location
			controller.unwinder?.unwind(to: view)
			strongSelf.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { view.present($0, animated: true)}
		})
		
		if let location = filter.location {
			let title: NSAttributedString?
			let object: NSManagedObject
			switch location {
			case let .solarSystem(solarSystem):
				object = solarSystem
				title = EVELocation(solarSystem).displayName
				
			case let .region(region):
				object = region
				title = NSAttributedString(string: region.regionName ?? "")
			}
			
			return Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.default,
															  attributedTitle: title,
															  accessoryType: .imageButton(Image(#imageLiteral(resourceName: "clear.pdf")), { [weak self] _ in
																self?.filter.location = nil
																self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
															})),
										 diffIdentifier: object,
										 route: route).asAnyItem
		}
		else {
			return Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.action,
															  title: NSLocalizedString("Solar System", comment: "").uppercased()),
										 diffIdentifier: "Location",
										 route: route).asAnyItem
		}
	}
	
	private func dateRow(shortTitle: String, fullTitle: String, range: ClosedRange<Date>, date: Date?, handler: @escaping (Date?) -> Void) -> AnyTreeItem {
		let route = Router.KillReports.datePicker(DatePicker.View.Input(title: fullTitle,
																		range: range,
																		current: date ?? Date(),
																		completion: { [weak self] (controller, date) in
																			handler(date)
																			self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
		}))
		
		if let date = date {
			return Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.default,
															  title: shortTitle,
															  subtitle: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none),
															  accessoryType: .imageButton(Image(#imageLiteral(resourceName: "clear.pdf")), { [weak self] _ in
																handler(nil)
																self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
															})),
										 diffIdentifier: Pair(shortTitle, date),
										 route: route).asAnyItem
		}
		else {
			return Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.action,
															  title: fullTitle.uppercased()),
										 diffIdentifier: shortTitle,
										 route: route).asAnyItem
		}
	}
	
	private var fromRow: AnyTreeItem {
		return dateRow(shortTitle: NSLocalizedString("From", comment: ""),
					   fullTitle: NSLocalizedString("From Date", comment: ""),
					   range: Date.distantPast...Date(),
					   date: filter.from) { [weak self] date in
						self?.filter.from = date
		}
	}
	
	private var toRow: AnyTreeItem {
		return dateRow(shortTitle: NSLocalizedString("To", comment: ""),
					   fullTitle: NSLocalizedString("To Date", comment: ""),
					   range: Date.distantPast...Date(),
					   date: filter.to) { [weak self] date in
						self?.filter.to = date
		}
	}
}


extension Tree.Item {
	class ZKillboardContactRow: ContactRow, Routable {
		var handler: (UIControl) -> Void
		var route: Routing?
		
		init(_ content: Contact, api: API, route: Routing?, handler: @escaping (UIControl) -> Void ) {
			self.handler = handler
			self.route = route
			super.init(content, api: api)
		}
		
		override func configure(cell: UITableViewCell, treeController: TreeController?) {
			super.configure(cell: cell, treeController: treeController)
			guard let cell = cell as? TreeDefaultCell else {return}
			
			let button = UIButton(frame: .zero)
			button.setImage(#imageLiteral(resourceName: "clear.pdf"), for: .normal)
			button.sizeToFit()
			cell.accessoryButtonHandler = ActionHandler(button, for: .touchUpInside, handler: handler)
			cell.accessoryView = button
		}
	}
}

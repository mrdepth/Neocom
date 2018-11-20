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
		enum Ship {
			case type(SDEInvType)
			case group(SDEInvGroup)
		}
		var from: Date?
		var to: Date?
		var pilot: Contact?
		var location: MapLocationPicker.View.Location?
		var ship: Ship?
	}
	
	var filter = Filter()
	
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		var result = Presentation()
		
		let contactsRoute = Router.KillReports.contacts(Contacts.View.Input { [weak self] (controller, contact) in
			guard let strongSelf = self, let view = strongSelf.view else {return}
			controller.unwinder?.unwind(to: view)
			strongSelf.filter.pilot = contact
			strongSelf.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { view.present($0, animated: true)}
		})
		
		if let contact = filter.pilot {
			let row = Tree.Item.ZKillboardContactRow(contact, api: interactor.api, route: contactsRoute) { [weak self] (_) in
				self?.filter.pilot = nil
				self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
			}
			result.append(row.asAnyItem)
		}
		else {
			let row = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.action,
															   title: NSLocalizedString("Pilot", comment: "").uppercased()),
										  diffIdentifier: "Pilot",
										  route: contactsRoute)
			result.append(row.asAnyItem)
		}
		
		let locationRow: Tree.Item.RoutableRow<Tree.Content.Default>
		
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
			
			locationRow = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.default,
															  attributedTitle: title,
															  accessoryType: .imageButton(Image(#imageLiteral(resourceName: "clear.pdf")), { [weak self] _ in
																self?.filter.location = nil
																self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
															})), diffIdentifier: object)
		}
		else {
			locationRow = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.action,
															  title: NSLocalizedString("Solar System", comment: "").uppercased()),
										 diffIdentifier: "Location")
		}
		
		locationRow.route = Router.SDE.mapLocationPicker(MapLocationPicker.View.Input(mode: .all) { [weak self] (controller, location) in
			guard let strongSelf = self, let view = strongSelf.view else {return}
			strongSelf.filter.location = location
			controller.unwinder?.unwind(to: view)
			strongSelf.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { view.present($0, animated: true)}
		})

		result.append(locationRow.asAnyItem)
		
		let from: Tree.Item.RoutableRow<Tree.Content.Default>
		
		if let date = filter.from {
			from = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.default,
															  title: NSLocalizedString("From", comment: ""),
															  subtitle: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none),
															  accessoryType: .imageButton(Image(#imageLiteral(resourceName: "clear.pdf")), { [weak self] _ in
																self?.filter.from = nil
																self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
															})), diffIdentifier: Pair("From", date))
		}
		else {
			from = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.action,
															  title: NSLocalizedString("From Date", comment: "").uppercased()),
										 diffIdentifier: "From")
		}
		from.route = Router.KillReports.datePicker(DatePicker.View.Input(title: NSLocalizedString("From Date", comment: ""),
																		 range: Date.distantPast...Date(),
																		 current: filter.from ?? Date(),
																		 completion: { [weak self] (controller, date) in
																			self?.filter.from = date
																			self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
		}))
		result.append(from.asAnyItem)
		
		let to: Tree.Item.RoutableRow<Tree.Content.Default>
		
		if let date = filter.to {
			to = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.default,
															title: NSLocalizedString("To", comment: ""),
															subtitle: DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: .none),
															accessoryType: .imageButton(Image(#imageLiteral(resourceName: "clear.pdf")), { [weak self] _ in
																self?.filter.to = nil
																self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
															})), diffIdentifier: Pair("To", date))
		}
		else {
			to = Tree.Item.RoutableRow(Tree.Content.Default(prototype: Prototype.TreeDefaultCell.action,
															title: NSLocalizedString("To Date", comment: "").uppercased()),
									   diffIdentifier: "To")
		}
		to.route = Router.KillReports.datePicker(DatePicker.View.Input(title: NSLocalizedString("To Date", comment: ""),
																	   range: Date.distantPast...Date(),
																	   current: filter.to ?? Date(),
																	   completion: { [weak self] (controller, date) in
																		self?.filter.to = date
																		self?.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { self?.view?.present($0, animated: true)}
		}))
		result.append(to.asAnyItem)
		
		
		return .init([Tree.Item.Virtual(children: result).asAnyItem])
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

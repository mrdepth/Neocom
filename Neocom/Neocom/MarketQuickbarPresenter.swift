//
//  MarketQuickbarPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class MarketQuickbarPresenter: TreePresenter {
	typealias View = MarketQuickbarViewController
	typealias Interactor = MarketQuickbarInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.NamedFetchedResultsSection<Tree.Item.InvType>>
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeHeaderCell.default,
								  Prototype.InvTypeCell.charge,
								  Prototype.InvTypeCell.default,
								  Prototype.InvTypeCell.module,
								  Prototype.InvTypeCell.ship])

		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let treeController = view?.treeController
		
		return Services.storage.performBackgroundTask { context -> Future<Presentation> in
			guard let typeIDs = context.marketQuickItems()?.map ({ $0.typeID }), !typeIDs.isEmpty else { throw NCError.noResults }
			return Services.sde.performBackgroundTask { context -> Presentation in
				let controller = context.managedObjectContext
					.from(SDEInvType.self)
					.filter((\SDEInvType.typeID).in(typeIDs))
					.sort(by: \SDEInvType.group?.category?.categoryName, ascending: true)
					.sort(by: \SDEInvType.typeName, ascending: true)
					.select(
						Tree.Item.InvType.propertiesToFetch +
							[(\SDEInvType.group?.category?.categoryName).as(String.self, name: "categoryName")])
					.fetchedResultsController(sectionName: (\SDEInvType.group?.category?.categoryName).as(String.self, name: "categoryName"))
				try controller.performFetch()
				return Presentation(controller, treeController: treeController)
			}
		}
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.InvType, let type = item.type, let view = view else {return}
		
		Router.SDE.invTypeInfo(.type(type)).perform(from: view)
	}

}

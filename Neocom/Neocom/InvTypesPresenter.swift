//
//  InvTypesPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 20.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures
import CloudData
import CoreData
import Expressible

class InvTypesPresenter: TreePresenter {
	typealias View = InvTypesViewController
	typealias Interactor = InvTypesPresenterInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsNamedSection<Tree.Item.InvType>>
	
	weak var view: View!
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view.tableView.register([Prototype.TreeHeaderCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		guard let input = view.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		return Services.sde.performBackgroundTask { context -> Presentation in
			let controller = Services.sde.viewContext.managedObjectContext
				.from(SDEInvType.self)
				.filter(input)
				.sort(by: \SDEInvType.metaGroup?.metaGroupID, ascending: true)
				.sort(by: \SDEInvType.metaLevel, ascending: true)
				.sort(by: \SDEInvType.typeName, ascending: true)
				.select([
					Self.as(NSManagedObjectID.self, name: "objectID"),
					(\SDEInvType.dgmppItem?.requirements).as(NSManagedObjectID.self, name: "requirements"),
					(\SDEInvType.dgmppItem?.shipResources).as(NSManagedObjectID.self, name: "shipResources"),
					(\SDEInvType.dgmppItem?.damage).as(NSManagedObjectID.self, name: "damage"),
					(\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName")])
				.fetchedResultsController(sectionName: (\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName"))
			try controller.performFetch()
			return Presentation(controller, treeController: self.view.treeController)
		}
	}
	
	func updateSearchResults(with string: String) {
	}
}

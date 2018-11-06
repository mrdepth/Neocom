//
//  InvTypeRequiredForPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/1/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible
import CoreData

class InvTypeRequiredForPresenter: TreePresenter {
	typealias View = InvTypeRequiredForViewController
	typealias Interactor = InvTypeRequiredForInteractor
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
		view?.tableView.register([Prototype.TreeSectionCell.default,
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
		guard let input = view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		let treeController = view?.treeController
		
		return Services.sde.performBackgroundTask { context -> Presentation in
			let invType: SDEInvType
			
			switch input {
			case let .objectID(objectID):
				invType = try! context.existingObject(with: objectID)!
			}
			let filter = (\SDEInvType.requiredSkills).any(\SDEInvTypeRequiredSkill.skillType) == invType
			
			let controller = context.managedObjectContext
				.from(SDEInvType.self)
				.filter(filter)
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

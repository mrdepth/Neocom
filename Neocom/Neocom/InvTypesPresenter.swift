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
		
		if let input = view?.input, let view = view {
			switch input {
			case let .category(category):
				view.title = category.categoryName
			case let .group(group):
				view.title = group.groupName
			case let .marketGroup(marketGroup):
				view.title = marketGroup?.marketGroupName
			case let .npcGroup(npcGroup):
				view.title = npcGroup?.npcGroupName
			case .none:
				break
			}
		}
		

	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		let treeController = view?.treeController
		
		var filter: Predictable
		
		switch input {
		case let .category(category):
			filter = \SDEInvType.group?.category == category
		case let .group(group):
			filter = \SDEInvType.group == group
		case let .marketGroup(marketGroup):
			if view?.parent is UISearchController {
				filter = \SDEInvType.marketGroup != nil
			}
			else {
				filter = \SDEInvType.marketGroup == marketGroup
			}
		case let .npcGroup(npcGroup):
			if view?.parent is UISearchController {
				filter = \SDEInvType.group?.category?.categoryID == SDECategoryID.entity.rawValue
			}
			else {
				filter = \SDEInvType.group == npcGroup?.group
			}
		case .none:
			filter = true
		}
		
		if view?.parent is UISearchController {
			let string = searchManager.pop() ?? ""
			filter = string.count > 2 ? filter && (\SDEInvType.typeName).caseInsensitive.contains(string) : false
		}
		
		
		
		return Services.sde.performBackgroundTask { context -> Presentation in
			let controller = context.managedObjectContext
				.from(SDEInvType.self)
				.filter(filter)
				.sort(by: \SDEInvType.metaGroup?.metaGroupID, ascending: true)
				.sort(by: \SDEInvType.metaLevel, ascending: true)
				.sort(by: \SDEInvType.typeName, ascending: true)
				.select(
					Tree.Item.InvType.propertiesToFetch +
						[(\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName")])
				.fetchedResultsController(sectionName: (\SDEInvType.metaGroup?.metaGroupName).as(String.self, name: "metaGroupName"))
			try controller.performFetch()
			return Presentation(controller, treeController: treeController)
		}
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.InvType, let type = item.type, let view = view else {return}
		
		Router.SDE.invTypeInfo(.type(type)).perform(from: view)
	}

	
	private lazy var searchManager = SearchManager(presenter: self)
	
	func updateSearchResults(with string: String) {
		searchManager.updateSearchResults(with: string)
	}
	
	
}

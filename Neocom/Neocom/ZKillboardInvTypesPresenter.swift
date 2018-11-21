//
//  ZKillboardInvTypesPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class ZKillboardInvTypesPresenter: TreePresenter {
	typealias View = ZKillboardInvTypesViewController
	typealias Interactor = ZKillboardInvTypesInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.NamedFetchedResultsSection<Tree.Item.ZKillboardInvType>>

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
								  Prototype.InvTypeCell.default,
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
		
		var filter: Predictable
		
		switch input {
		case let .category(category):
			filter = \SDEInvType.group?.category == category
		case let .group(group):
			filter = \SDEInvType.group == group
		case .none:
			filter = (\SDEInvType.group?.category?.categoryID).in([SDECategoryID.ship.rawValue, SDECategoryID.structure.rawValue])
		}
		
		if view?.parent is UISearchController {
			let string = searchManager.pop() ?? ""
			filter = string.count > 2 ? filter && (\SDEInvType.typeName).caseInsensitive.contains(string) : false
		}
		
		return Services.sde.performBackgroundTask { context -> Presentation in
			let controller = context.managedObjectContext
				.from(SDEInvType.self)
				.filter(filter)
				.filter(\SDEInvType.published == true)
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
		guard let view = view?.parent as? ZKillboardTypePickerViewController else {return}
		guard let item = item as? Tree.Item.InvType, let type = item.type else {return}
		view.input?(view, .type(type))
	}
	
	func accessoryButtonTapped<T: TreeItem>(for item: T) {
		guard let item = item as? Tree.Item.InvType, let type = item.type, let view = view else {return}
		Router.SDE.invTypeInfo(.type(type)).perform(from: view)
	}
	
	
	private lazy var searchManager = SearchManager(presenter: self)
	
	func updateSearchResults(with string: String) {
		searchManager.updateSearchResults(with: string)
	}
}

extension Tree.Item {
	class ZKillboardInvType: InvType {
		required init(_ result: Result, section: FetchedResultsSectionProtocol) {
			super.init(result, section: section)
			secondaryRoute = route
			route = nil
		}
	}
}

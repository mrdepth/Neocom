//
//  DgmTypePickerTypesPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 24/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class DgmTypePickerTypesPresenter: TreePresenter {
	typealias View = DgmTypePickerTypesViewController
	typealias Interactor = DgmTypePickerTypesInteractor
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
			case .category:
				view.title = nil
			case let .group(group):
				view.title = group.groupName
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
			filter = (\SDEInvType.dgmppItem?.groups).any(\SDEDgmppItemGroup.category) == category
		case let .group(group):
			filter = (\SDEInvType.dgmppItem?.groups).contains(group)
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
		guard let item = item as? Tree.Item.InvType, let type = item.type else {return}
		guard let controller = view?.navigationController as? DgmTypePickerViewController else {return}
		interactor.touch(type)
		controller.input?.completion(controller, type)
	}
	
	
	private lazy var searchManager = SearchManager(presenter: self)
	
	func updateSearchResults(with string: String) {
		searchManager.updateSearchResults(with: string)
	}
	
	
}

//
//  ZKillboardInvGroupsPresenter.swift
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

class ZKillboardInvGroupsPresenter: TreePresenter {
	typealias View = ZKillboardInvGroupsViewController
	typealias Interactor = ZKillboardInvGroupsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.FetchedResultsRow<SDEInvGroup>>>

	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeDefaultCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}

		let frc = Services.sde.viewContext.managedObjectContext
			.from(SDEInvGroup.self)
			.filter(\SDEInvGroup.category == input && \SDEInvGroup.published == true)
			.sort(by: \SDEInvGroup.groupName, ascending: true)
			.fetchedResultsController()
		
		let result = Presentation(frc, treeController: view?.treeController)
		return .init(result)
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEInvGroup>, let view = view else {return}
		Router.KillReports.typePickerInvTypes(.group(item.result)).perform(from: view)
	}
	
	func select(_ group: SDEInvGroup) {
		guard let view = view?.parent as? ZKillboardTypePickerViewController else {return}
		view.input?(view, .group(group))
	}
}

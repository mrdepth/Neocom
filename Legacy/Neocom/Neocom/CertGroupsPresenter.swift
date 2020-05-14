//
//  CertGroupsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/28/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class CertGroupsPresenter: TreePresenter {
	typealias View = CertGroupsViewController
	typealias Interactor = CertGroupsInteractor
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
		let controller = Services.sde.viewContext.managedObjectContext
			.from(SDEInvGroup.self)
			.filter((\SDEInvGroup.certificates).count > 0)
			.sort(by: \SDEInvGroup.groupName, ascending: true)
			.fetchedResultsController()
		
		return .init(Presentation(controller, treeController: view?.treeController))
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEInvGroup>, let view = view else {return}
		Router.SDE.certCertificates(item.result).perform(from: view)
	}

}

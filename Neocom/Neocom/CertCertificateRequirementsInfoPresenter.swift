//
//  CertCertificateRequirementsInfoPresenter.swift
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

class CertCertificateRequirementsInfoPresenter: TreePresenter {
	typealias View = CertCertificateRequirementsInfoViewController
	typealias Interactor = CertCertificateRequirementsInfoInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.NamedFetchedResultsSection<Tree.Item.FetchedResultsRow<SDEInvType>>>
	
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
								  Prototype.TreeDefaultCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		guard let input = view?.input else { return .init(.failure(NCError.invalidInput(type: type(of: self))))}
		
		let controller = Services.sde.viewContext.managedObjectContext
			.from(SDEInvType.self)
			.filter(\SDEInvType.published == true && (\SDEInvType.certificates).contains(input))
			.sort(by: \SDEInvType.group?.groupName, ascending: true)
			.fetchedResultsController(sectionName: \SDEInvType.group?.groupName, cacheName: nil)
		
		
		return .init(Presentation(controller, treeController: view?.treeController))
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEInvType>, let view = view else {return}
		Router.SDE.invTypeInfo(.type(item.result)).perform(from: view)
	}

}

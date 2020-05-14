//
//  ZKillboardInvCategoriesPresenter.swift
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

class ZKillboardInvCategoriesPresenter: TreePresenter {
	typealias View = ZKillboardInvCategoriesViewController
	typealias Interactor = ZKillboardInvCategoriesInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.FetchedResultsRow<SDEInvCategory>>>
	
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
		let frc = Services.sde.viewContext.managedObjectContext
			.from(SDEInvCategory.self)
			.filter((\SDEInvCategory.categoryID).in([SDECategoryID.ship.rawValue, SDECategoryID.structure.rawValue]))
			.sort(by: \SDEInvCategory.categoryName, ascending: true)
			.fetchedResultsController()
		
		return .init(Presentation(frc, treeController: view?.treeController))
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard let item = item as? Tree.Item.FetchedResultsRow<SDEInvCategory> else {return}
		guard let view = view else {return}
		Router.KillReports.typePickerInvGroups(item.result).perform(from: view)
	}

}

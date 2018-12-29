//
//  FittingFleetsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 25/12/2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController
import Expressible

class FittingFleetsPresenter: TreePresenter {
	typealias View = FittingFleetsViewController
	typealias Interactor = FittingFleetsInteractor
	typealias Presentation = Tree.Item.FetchedResultsController<Tree.Item.FetchedResultsSection<Tree.Item.FleetFetchedResultsRow>>
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.FleetCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let frc = Services.storage.viewContext.managedObjectContext
			.from(Fleet.self)
			.sort(by: \Fleet.name, ascending: true)
			.fetchedResultsController()
		
		return .init(Presentation(frc, treeController: view?.treeController))
	}
}

//
//  InvGroupsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class InvGroupsPresenter: TreePresenter {
	typealias View = InvGroupsViewController
	typealias Interactor = InvGroupsInteractor
	typealias Presentation = [Tree.Item.Row<Tree.Content.Default>]
	
	weak var view: View!
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view.tableView.register([Prototype.TreeDefaultCell.default, Prototype.TreeHeaderCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		return .init([])
	}
}

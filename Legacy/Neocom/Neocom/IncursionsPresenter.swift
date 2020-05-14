//
//  IncursionsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class IncursionsPresenter: TreePresenter {
	typealias View = IncursionsViewController
	typealias Interactor = IncursionsInteractor
	typealias Presentation = [Tree.Item.IncursionRow]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.TreeDefaultCell.default,
								  Prototype.IncursionCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		
		let rows = content.value.map { Tree.Item.IncursionRow($0, api: interactor.api) }
		
		return .init(rows)
	}
}

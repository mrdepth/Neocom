//
//  KillmailsPagePresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class KillmailsPagePresenter: TreePresenter {
	typealias View = KillmailsPageViewController
	typealias Interactor = KillmailsPageInteractor
	typealias Presentation = [Tree.Item.Section<Tree.Content.Section, Tree.Item.KillmailRow>]
	
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
								  Prototype.KillmailCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let dateFormatter = DateFormatter()
		dateFormatter.dateStyle = .medium
		dateFormatter.timeStyle = .none
		dateFormatter.doesRelativeDateFormatting = true
		let sections = content.map {
			Tree.Item.Section(Tree.Content.Section(title: dateFormatter.string(from: $0.date).uppercased()), diffIdentifier: $0.date, treeController: view?.treeController, children: $0.rows)
		}
		return .init(sections)
	}
	
	@discardableResult
	func fetchIfNeeded() -> Future<Void> {
		guard let parent = (view?.parent as? KillmailsViewController) else {return .init(.failure(NCError.reloadInProgress))}
		return parent.presenter.fetchIfNeeded()
	}
}

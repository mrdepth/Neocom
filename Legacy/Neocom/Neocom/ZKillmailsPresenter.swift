//
//  ZKillmailsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import TreeController

class ZKillmailsPresenter: TreePresenter {
	typealias View = ZKillmailsViewController
	typealias Interactor = ZKillmailsInteractor
	typealias Presentation = [Tree.Item.Virtual<Tree.Item.ZKillmailRow, Int>]
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view?.tableView.register([Prototype.KillmailCell.default])

		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let old = self.presentation ?? []
		
		let api = interactor.api
		
		return DispatchQueue.global(qos: .utility).async { () -> Presentation in
			var killmails = content.value
			let ids = Set(old.flatMap{$0.children?.map{$0.content.killmailID} ?? []})
			if !ids.isEmpty {
				killmails.removeAll {ids.contains($0.killmailID)}
			}
			
			let new = killmails.map {
				Tree.Item.ZKillmailRow($0, api: api)
			}
			return old + [Tree.Item.Virtual(children: new, diffIdentifier: old.count)]
		}
	}
	
	var currentPage: Int?
	func prepareForReload() {
		self.presentation = nil
		self.currentPage = nil
		self.isEndReached = false
	}
	
	private var isEndReached = false
	
	@discardableResult
	func fetchIfNeeded() -> Future<Presentation> {
		guard !isEndReached else {return .init(.failure(NCError.isEndReached))}
		guard self.loading == nil else {return .init(.failure(NCError.reloadInProgress))}
		
		view?.activityIndicator.startAnimating()
		let loading = interactor.load(page: (currentPage ?? 1) + 1, cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak self] content -> Future<Presentation> in
			guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
			guard !content.value.isEmpty else {throw NCError.isEndReached}
			return strongSelf.presentation(for: content).then(on: .main) { [weak self] presentation -> Presentation in
				self?.presentation = presentation
				self?.view?.present(presentation, animated: false)
				self?.loading = nil
				return presentation
			}
		}.catch(on: .main) { [weak self] error in
			self?.loading = nil
			self?.isEndReached = true
		}.finally(on: .main) { [weak self] in
			self?.view?.activityIndicator.stopAnimating()
		}
		
		if case .pending = loading.state {
			self.loading = loading
		}
		return loading
	}
}

//
//  Snippets.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class <#T##View#>: TreeViewController<<#T##Presenter#>>, TreeView {
}

class <#T##Presenter#>: TreePresenter {
	typealias View = <#T##View#>
	typealias Interactor = <#T##Interactor#>
	typealias Presentation = <#T##Presentation#>
	
	weak var view: View!
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		view.tableView.register([<#T##Prototype#>])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		return .init(<#presentation#>)
	}
}

class <#T##Interactor#>: TreeInteractor {
	typealias Presenter = <#T##Presenter#>
	typealias Content = <#T##Content#>
	weak var presenter: Presenter!
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return .init(<#content#>)
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			_ = self?.presenter.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter.view.present(presentation, animated: true)
			}
		}
	}
}

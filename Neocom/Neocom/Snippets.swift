//
//  Snippets.swift
//  Neocom
//
//  Created by Artem Shimanski on 05.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class <#T##View#>: UITableViewController, TreeView {
	typealias Presenter = <#T##Presenter#>
	
	lazy var presenter: Presenter! = Presenter(view: self)
	var unwinder: Unwinder?
	lazy var treeController: TreeController! = TreeController()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.delegate = self
		treeController.scrollViewDelegate = self
		treeController.tableView = tableView
		presenter.configure()
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
}

class <#T##Presenter#>: TreePresenter {
	typealias View = <#T##View#>
	typealias Interactor = <#T##Interactor#>
	typealias Presentation = <#T##Presentation#>
	
	weak var view: View!
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Void>?
	
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
}

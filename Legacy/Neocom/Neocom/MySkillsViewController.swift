//
//  MySkillsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 10/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class MySkillsViewController: PageViewController, ContentProviderView {
	typealias Presenter = MySkillsPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	
	var unwinder: Unwinder?
	
	
	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void> {
		let pages = viewControllers as? [MySkillsPageViewController]
		
		zip((0..<4), [content.all, content.canTrain, content.notKnown, content.all]).forEach {
			pages?[$0].input = $1
			pages?[$0].presenter.reloadIfNeeded()
		}

		return .init(())
	}
	
	func fail(_ error: Error) {
		let pages = viewControllers as? [MySkillsPageViewController]
		pages?.forEach {
			$0.fail(error)
		}
	}
	
	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()
		
		
		try! viewControllers = [NSLocalizedString("My", comment: ""),
								NSLocalizedString("Can Train", comment: ""),
								NSLocalizedString("Not Known", comment: ""),
								NSLocalizedString("All", comment: "")].map { title -> UIViewController in
									let view = try MySkillsPage.default.instantiate([]).get()
									view.title = title
									return view
		}
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

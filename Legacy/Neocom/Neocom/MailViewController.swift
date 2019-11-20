//
//  MailViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/2/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class MailViewController: PageViewController, ContentProviderView {
	
	
	typealias Presenter = MailPresenter
	lazy var presenter: Presenter! = Presenter(view: self)
	
	var unwinder: Unwinder?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		presenter.configure()
		navigationController?.isToolbarHidden = false
		navigationItem.rightBarButtonItem = editButtonItem
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
	
	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void> {
		var pages = viewControllers as? [MailPageViewController] ?? []
		errorLabel = nil
		
		viewControllers = content.value.labels?.map { i -> UIViewController in
			let controller: MailPageViewController
			if let i = pages.firstIndex(where: {$0.input?.labelID == i.labelID}) {
				controller = pages.remove(at: i)
			}
			else {
				controller = try! MailPage.default.instantiate(i).get()
			}
			
			controller.updateTitle()

			return controller
		}
		
		return .init(())
	}
	
	func fail(_ error: Error) {
		errorLabel = TableViewBackgroundLabel(error: error)
	}
	
	private var errorLabel: UILabel? {
		didSet {
			oldValue?.removeFromSuperview()
			if let label = errorLabel {
				view.addSubview(label)
				if #available(iOS 11.0, *) {
					label.frame = view.bounds.inset(by: view.safeAreaInsets)
				} else {
					label.frame = view.bounds.inset(by: UIEdgeInsets(top: topLayoutGuide.length, left: 0, bottom: bottomLayoutGuide.length, right: 0))
				}
			}
		}
	}
}

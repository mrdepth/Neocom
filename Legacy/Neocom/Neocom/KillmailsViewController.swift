//
//  KillmailsViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/13/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class KillmailsViewController: PageViewController, ContentProviderView {
	typealias Presenter = KillmailsPresenter

	lazy var presenter: Presenter! = Presenter(view: self)
	var unwinder: Unwinder?
	
	var killsViewController: KillmailsPageViewController?
	var lossesViewController: KillmailsPageViewController?

	
	override func viewDidLoad() {
		super.viewDidLoad()
		
		killsViewController = try! KillmailsPage.default.instantiate().get()
		lossesViewController = try! KillmailsPage.default.instantiate().get()
		killsViewController?.title = NSLocalizedString("Kills", comment: "")
		lossesViewController?.title = NSLocalizedString("Losses", comment: "")
		viewControllers = [killsViewController!, lossesViewController!]
		
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
	
	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void> {
		killsViewController?.input = content.kills
		lossesViewController?.input = content.losses
		killsViewController?.presenter.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak killsViewController] presentation in
			killsViewController?.present(presentation, animated: false)
		}
		lossesViewController?.presenter.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { [weak lossesViewController] presentation in
			lossesViewController?.present(presentation, animated: false)
		}
		return .init(())
	}
	
	func fail(_ error: Error) {
		killsViewController?.fail(error)
		lossesViewController?.fail(error)
	}

}

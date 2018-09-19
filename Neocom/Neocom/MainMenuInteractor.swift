//
//  MainMenuInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class MainMenuInteractor: TreeInteractor {
	typealias Presenter = MainMenuPresenter
	weak var presenter: Presenter!
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	private var didChangeAccountObserver: NotificationObserver?
	var api: API = Services.api.current
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			self?.api = Services.api.current
			_ = self?.presenter.reload(cachePolicy: .useProtocolCachePolicy).then(on: .main) { presentation in
				self?.presenter.view.present(presentation, animated: true)
			}
		}
	}
	
}


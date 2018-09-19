//
//  MainMenuContainerInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CloudData

class MainMenuContainerInteractor: Interactor {
	weak var presenter: MainMenuContainerPresenter!
	
	private var didChangeAccountObserver: NotificationObserver?

	required init(presenter: MainMenuContainerPresenter) {
		self.presenter = presenter
	}
	
	func configure() {
		didChangeAccountObserver = NotificationCenter.default.addNotificationObserver(forName: .didChangeAccount, object: nil, queue: .main) { [weak self] _ in
			self?.presenter.view.updateHeader()
		}
	}

}

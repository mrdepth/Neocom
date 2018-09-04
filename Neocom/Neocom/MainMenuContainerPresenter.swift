//
//  MainMenuContainerPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI

class MainMenuContainerPresenter: Presenter {
	weak var view: MainMenuContainerViewController!
	lazy var interactor: MainMenuContainerInteractor! = MainMenuContainerInteractor(presenter: self)
	
	required init(view: MainMenuContainerViewController) {
		self.view = view
	}
	
	func onHeaderTap() {
		if let count = try? Services.storage.viewContext.managedObjectContext.from(Account.self).count(), count == 0 {
			Services.api.performAuthorization(from: self.view)
		}
		else {
			Router.MainMenu.accounts().perform(from: view)
		}
	}
	
	func onPan(_ sender: UIPanGestureRecognizer) {
		if sender.state == .began && sender.translation(in: view.view).y > 0 {
			Router.MainMenu.accounts().perform(from: view)
		}
	}
}

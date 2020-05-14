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
	typealias View = MainMenuContainerViewController
	typealias Interactor = MainMenuContainerInteractor

	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)

	required init(view: View) {
		self.view = view
	}
	
	func onHeaderTap() {
		guard let view = view else {return}
		if let count = try? Services.storage.viewContext.managedObjectContext.from(Account.self).count(), count == 0 {
			Services.api.performAuthorization(from: view)
		}
		else {
			Router.MainMenu.accounts().perform(from: view)
		}
	}
	
	func onPan(_ sender: UIPanGestureRecognizer) {
		guard let view = view else {return}
		if sender.state == .began && sender.translation(in: view.view).y > 0 {
			Router.MainMenu.accounts().perform(from: view)
		}
	}
}

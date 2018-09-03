//
//  MainMenuHeaderPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import EVEAPI

class MainMenuHeaderPresenter: ContentProviderPresenter {
	var content: ESI.Result<MainMenuHeaderInteractor.Info>?
	var presentation: MainMenuHeaderInteractor.Info?
	var isLoading: Bool = false
	
	func presentation(for content: ESI.Result<MainMenuHeaderInteractor.Info>) -> Future<MainMenuHeaderInteractor.Info> {
		return .init(content.value)
	}

	weak var view: MainMenuHeaderViewController!
	lazy var interactor: MainMenuHeaderInteractor! = MainMenuHeaderInteractor(presenter: self)

	required init(view: MainMenuHeaderViewController) {
		self.view = view
	}
}

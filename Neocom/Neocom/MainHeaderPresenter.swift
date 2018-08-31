//
//  MainHeaderPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import EVEAPI

class MainHeaderPresenter: ContentProviderPresenter {
	var content: ESI.Result<MainHeaderInteractor.Info>?
	var presentation: MainHeaderInteractor.Info?
	var isLoading: Bool = false
	
	func presentation(for content: ESI.Result<MainHeaderInteractor.Info>) -> Future<MainHeaderInteractor.Info> {
		return .init(content.value)
	}

	weak var view: MainHeaderViewController!
	lazy var interactor: MainHeaderInteractor! = MainHeaderInteractor(presenter: self)

	required init(view: MainHeaderViewController) {
		self.view = view
	}
}

//
//  MainHeaderPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class MainHeaderPresenter: Presenter {
	weak var view: MainHeaderViewController!
	lazy var interactor: MainHeaderInteractor! = MainHeaderInteractor(presenter: self)

	required init(view: MainHeaderViewController) {
		self.view = view
	}
}

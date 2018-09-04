//
//  MainMenuContainerInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 04.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class MainMenuContainerInteractor: Interactor {
	weak var presenter: MainMenuContainerPresenter!
	
	required init(presenter: MainMenuContainerPresenter) {
		self.presenter = presenter
	}
}

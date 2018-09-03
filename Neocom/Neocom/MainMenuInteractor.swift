//
//  MainMenuInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

class MainMenuInteractor: TreeInteractor {
	weak var presenter: MainMenuPresenter!

	required init(presenter: MainMenuPresenter) {
		self.presenter = presenter
	}
	
}

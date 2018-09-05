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
	typealias Presenter = MainMenuPresenter
	weak var presenter: Presenter!
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
}


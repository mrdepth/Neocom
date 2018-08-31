//
//  MainInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

class MainInteractor: TreeInteractor {
	weak var presenter: MainPresenter!

	required init(presenter: MainPresenter) {
		self.presenter = presenter
	}
	
}

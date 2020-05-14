//
//  NewMailInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/5/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import EVEAPI
import Futures

class NewMailInteractor: Interactor {
	typealias Presenter = NewMailPresenter
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func configure() {
	}
	
	var api = Services.api.current
}

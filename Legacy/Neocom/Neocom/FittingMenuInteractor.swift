//
//  FittingMenuInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/23/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class FittingMenuInteractor: Interactor {
	typealias Presenter = FittingMenuPresenter
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func configure() {
	}
}

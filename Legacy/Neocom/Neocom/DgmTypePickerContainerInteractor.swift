//
//  DgmTypePickerContainerInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/30/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class DgmTypePickerContainerInteractor: Interactor {
	typealias Presenter = DgmTypePickerContainerPresenter
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func configure() {
	}
}

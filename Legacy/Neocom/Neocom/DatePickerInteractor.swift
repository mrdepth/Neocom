//
//  DatePickerInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/20/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class DatePickerInteractor: Interactor {
	typealias Presenter = DatePickerPresenter
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func configure() {
	}
}

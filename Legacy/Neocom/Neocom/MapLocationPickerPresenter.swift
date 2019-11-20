//
//  MapLocationPickerPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class MapLocationPickerPresenter: Presenter {
	typealias View = MapLocationPickerViewController
	typealias Interactor = MapLocationPickerInteractor
	
	weak var view: View?
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	required init(view: View) {
		self.view = view
	}
	
	func configure() {
		
		interactor.configure()
	}
}

//
//  MapLocationPickerSolarSystemsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class MapLocationPickerSolarSystemsInteractor: TreeInteractor {
	typealias Presenter = MapLocationPickerSolarSystemsPresenter
	typealias Content = Void
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
}

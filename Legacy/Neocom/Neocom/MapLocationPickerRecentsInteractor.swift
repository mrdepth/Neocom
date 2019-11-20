//
//  MapLocationPickerRecentsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class MapLocationPickerRecentsInteractor: TreeInteractor {
	typealias Presenter = MapLocationPickerRecentsPresenter
	typealias Content = Void
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	

}

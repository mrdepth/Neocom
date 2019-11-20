//
//  MapLocationPickerSearchResultsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 9/27/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class MapLocationPickerSearchResultsInteractor: TreeInteractor {
	typealias Presenter = MapLocationPickerSearchResultsPresenter
	typealias Content = Void
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
}

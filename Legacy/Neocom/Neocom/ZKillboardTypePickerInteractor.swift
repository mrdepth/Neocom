//
//  ZKillboardTypePickerInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class ZKillboardTypePickerInteractor: Interactor {
	typealias Presenter = ZKillboardTypePickerPresenter
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
}

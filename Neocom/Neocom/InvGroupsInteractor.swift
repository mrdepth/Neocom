//
//  InvGroupsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 19.09.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class InvGroupsInteractor: TreeInteractor {
	typealias Presenter = InvGroupsPresenter
	typealias Content = Void
	weak var presenter: Presenter!
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
}

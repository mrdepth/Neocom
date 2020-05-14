//
//  ZKillboardInvGroupsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/21/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData

class ZKillboardInvGroupsInteractor: TreeInteractor {
	typealias Presenter = ZKillboardInvGroupsPresenter
	typealias Content = Void
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
}

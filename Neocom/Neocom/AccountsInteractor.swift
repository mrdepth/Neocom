//
//  AccountsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class AccountsInteractor: TreeInteractor {
	weak var presenter: AccountsPresenter!
	lazy var cache: Cache! = CacheContainer.shared
	lazy var sde: SDE! = SDEContainer.shared
	lazy var storage: Storage! = StorageContainer.shared
	
	required init(presenter: AccountsPresenter) {
		self.presenter = presenter
	}

}

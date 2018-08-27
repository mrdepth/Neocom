//
//  MainInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 27.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures

class MainInteractor: TreeInteractor {
	weak var presenter: MainPresenter!
	lazy var cache: Cache! = CacheContainer.shared
	lazy var sde: SDE! = SDEContainer.shared
	lazy var storage: Storage! = StorageContainer.shared

	required init(presenter: MainPresenter) {
		self.presenter = presenter
	}
	
	func isExpired(_ content: ()) -> Bool {
		return false
	}
	
	func configure() {
	}
}

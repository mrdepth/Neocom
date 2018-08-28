//
//  MainHeaderInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 28.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation

class MainHeaderInteractor: Interactor {
	weak var presenter: MainHeaderPresenter!
	lazy var cache: Cache! = CacheContainer.shared
	lazy var sde: SDE! = SDEContainer.shared
	lazy var storage: Storage! = StorageContainer.shared

	required init(presenter: MainHeaderPresenter) {
		self.presenter = presenter
	}
	
	func configure() {
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) {
		let api = self.api(cachePolicy: cachePolicy)
	}
}

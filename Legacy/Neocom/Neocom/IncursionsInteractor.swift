//
//  IncursionsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 11/6/18.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import Futures
import CloudData
import EVEAPI

class IncursionsInteractor: TreeInteractor {
	typealias Presenter = IncursionsPresenter
	typealias Content = ESI.Result<[ESI.Incursions.Incursion]>
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	var api = Services.api.current
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return api.incursions(cachePolicy: cachePolicy)
	}
}

//
//  AccountsInteractor.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import CoreData
import Expressible
import Futures

class AccountsInteractor: TreeInteractor {
	
	typealias Presenter = AccountsPresenter
	typealias Content = URLRequest.CachePolicy
	weak var presenter: Presenter?
	
	required init(presenter: Presenter) {
		self.presenter = presenter
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content> {
		return .init(cachePolicy)
	}
	
	func isExpired(_ content: URLRequest.CachePolicy) -> Bool {
		return false
	}

}

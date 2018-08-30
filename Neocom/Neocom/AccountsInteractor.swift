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
	weak var presenter: AccountsPresenter!
	lazy var cache: Cache! = CacheContainer.shared
	lazy var sde: SDE! = SDEContainer.shared
	lazy var storage: Storage! = StorageContainer.shared
	
	required init(presenter: AccountsPresenter) {
		self.presenter = presenter
	}
	
	typealias Content = NSFetchedResultsController<Account>
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<NSFetchedResultsController<Account>> {
		let request = storage.viewContext.managedObjectContext.from(Account.self).sort(by: \Account.order, ascending: true).sort(by: \Account.characterName, ascending: true).fetchRequest
		
		return .init(NSFetchedResultsController(fetchRequest: request, managedObjectContext: storage.viewContext.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil))
	}

	func isExpired(_ content: NSFetchedResultsController<Account>) -> Bool {
		return false
	}

}

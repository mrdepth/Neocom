//
//  AccountsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import CoreData
import Futures

class AccountsPresenter: TreePresenter {
	typealias Item = AnyTreeItem
	
	weak var view: AccountsViewController!
	lazy var interactor: AccountsInteractor! = AccountsInteractor(presenter: self)

	required init(view: AccountsViewController) {
		self.view = view
	}

	var presentation: [AnyTreeItem]?
	var content: NSFetchedResultsController<Account>?
	
	var isLoading: Bool = false
	
	func presentation(for content: NSFetchedResultsController<Account>) -> Future<[AnyTreeItem]> {
		return .init([])
	}
}

extension Tree.Item {
	class AccountsResultsController: FetchedResultsController<Account, FetchedResultsSection<Account, AccountsItem>, AccountsItem> {
		weak var presenter: AccountsPresenter?
		
		init<T>(_ fetchedResultsController: NSFetchedResultsController<Account>, diffIdentifier: T, presenter: AccountsPresenter) where T : Hashable {
			self.presenter = presenter
			super.init(fetchedResultsController, diffIdentifier: diffIdentifier, treeController: presenter.view.treeController)
		}
	}
}

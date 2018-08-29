//
//  AccountsPresenter.swift
//  Neocom
//
//  Created by Artem Shimanski on 29.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

class AccountsPresenter: TreePresenter {
	typealias Item = AnyTreeItem
	
	weak var view: AccountsViewController!
	lazy var interactor: AccountsInteractor! = AccountsInteractor(presenter: self)

	required init(view: AccountsViewController) {
		self.view = view
	}

	var presentation: [AnyTreeItem]?
	
	var isLoading: Bool = false
	
	func presentation(for content: ()) -> Future<[AnyTreeItem]> {
		return .init([])
	}
}

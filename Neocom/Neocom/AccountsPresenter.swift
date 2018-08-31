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
import Expressible

class AccountsPresenter: TreePresenter {
	typealias Item = AnyTreeItem
	
	weak var view: AccountsViewController!
	lazy var interactor: AccountsInteractor! = AccountsInteractor(presenter: self)

	required init(view: AccountsViewController) {
		self.view = view
	}

	var presentation: [AnyTreeItem]?
//	var content: NSFetchedResultsController<Account>?
	
	var isLoading: Bool = false
	
	func presentation(for content: ()) -> Future<[AnyTreeItem]> {
		return .init([])
	}
}

extension Tree.Item {
	/*class AccountFoldersResultsController: FetchedResultsController<AccountsFolder, FetchedResultsSection<AccountsFolder, AccountsFolderItem>, AccountsFolderItem> {
	}
	
	class AccountsFolderItem: FetchedResultsItem<AccountsFolder>, CellConfiguring {
		typealias Child = AccountsResultsController
		lazy var children: [AccountsResultsController]? = {
			
			let request = content.managedObjectContext!.from(Account.self)
				.filter(\Account.folder == content)
				.sort(by: \Account.folder, ascending: true).sort(by: \Account.characterName, ascending: true)
				.fetchRequest
			
			let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: content.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
			return [AccountsResultsController(frc, treeController: section?.controller?.treeController)]
		}()
		
		var prototype: Prototype? {
			return Prototype.TreeHeaderCell.default
		}
		
		func configure(cell: UITableViewCell) {
			guard let cell = cell as? TreeHeaderCell else {return}
			cell.titleLabel?.text = content.name
		}

	}*/
	
//	class AccountsResultsController: FetchedResultsController<Account, FetchedResultsSection<Account, AccountsItem>, AccountsItem> {
//	}
	
	/*class AccountsDefaultFolder: Tree.Item.Collection<Tree.Content.Default, AccountsResultsController> {
		weak var treeController: TreeController?
		
		init(treeController: TreeController?) {
			let managedObjectContext = Services.storage.viewContext.managedObjectContext
			
			let request = managedObjectContext.from(Account.self)
				.filter(\Account.folder == nil)
				.sort(by: \Account.folder, ascending: true).sort(by: \Account.characterName, ascending: true)
				.fetchRequest
			
			let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
			let children = [AccountsResultsController(frc, treeController: treeController)]

			self.treeController = treeController
			super.init(Tree.Content.Default(title: "asdf"), diffIdentifier: "root", children: children)
		}
	}*/
}

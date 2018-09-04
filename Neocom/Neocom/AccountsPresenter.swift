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
import CloudData

class AccountsPresenter: TreePresenter {
	typealias Item = AnyTreeItem
	
	weak var view: AccountsViewController!
	lazy var interactor: AccountsInteractor! = AccountsInteractor(presenter: self)

	required init(view: AccountsViewController) {
		self.view = view
	}

	func configure() {
		view.tableView.register([Prototype.TreeHeaderCell.default,
								 Prototype.AccountCell.default])
		
		interactor.configure()
		applicationWillEnterForegroundObserver = NotificationCenter.default.addNotificationObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { [weak self] (note) in
			self?.applicationWillEnterForeground()
		}
	}
	
	private var applicationWillEnterForegroundObserver: NotificationObserver?
	
	var presentation: [AnyTreeItem]?
	
	var isLoading: Bool = false
	
	func presentation(for content: ()) -> Future<[AnyTreeItem]> {
		let folders = Tree.Item.AccountFoldersResultsController(context: Services.storage.viewContext, treeController: view.treeController)
		let defaultFolder = Tree.Item.AccountsDefaultFolder(treeController: view.treeController)
		return .init([defaultFolder.asAnyItem, folders.asAnyItem])
	}
	
	func onPan(_ sender: UIPanGestureRecognizer) {
		if sender.state == .began && sender.translation(in: view.view).y < 0 {
			view.unwinder?.unwind()
//			view.dismiss(animated: true, completion: nil)
		}
	}

}

extension Tree.Item {
	
	class AccountFoldersResultsController: FetchedResultsController<FetchedResultsSection<AccountsFolderItem>> {
		convenience init(context: StorageContext, treeController: TreeController?) {
			let fetchRequest = context.managedObjectContext.from(AccountsFolder.self).sort(by: \AccountsFolder.name, ascending: true).fetchRequest
			let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
			self.init(frc, treeController: treeController)
		}
	}
	
	class AccountsFolderItem: Tree.Item.Section<AccountsResultsController>, FetchedResultsTreeItem {
		var result: AccountsFolder
		unowned var section: FetchedResultsSectionProtocol
		
		private lazy var _children: [AccountsResultsController]? = {
			let request = result.managedObjectContext!.from(Account.self)
				.filter(\Account.folder == result)
				.sort(by: \Account.folder, ascending: true).sort(by: \Account.characterName, ascending: true)
				.fetchRequest
			
			let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: result.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
			return [AccountsResultsController(frc, treeController: section.controller.treeController)]
		}()
		
		override var children: [AccountsResultsController]? {
			get {
				return _children
			}
			set {
				_children = newValue
			}
		}
		
		required init(_ result: AccountsFolder, section: FetchedResultsSectionProtocol) {
			self.result = result
			self.section = section
			super.init(Tree.Content.Section(title: result.name), diffIdentifier: result, expandIdentifier: result.objectID, treeController: section.controller.treeController)
		}
	}
	
	class AccountsResultsController: FetchedResultsController<FetchedResultsSection<AccountsItem>> {
	}
	
	class AccountsDefaultFolder: Tree.Item.Section<AccountsResultsController> {
		
		init(treeController: TreeController?) {
			let managedObjectContext = Services.storage.viewContext.managedObjectContext
			
			let request = managedObjectContext.from(Account.self)
				.filter(\Account.folder == nil)
				.sort(by: \Account.folder, ascending: true).sort(by: \Account.characterName, ascending: true)
				.fetchRequest
			
			let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
			let children = [AccountsResultsController(frc, treeController: treeController)]

			super.init(Tree.Content.Section(title: "Default"), diffIdentifier: "defaultFolder", expandIdentifier: "defaultFolder", treeController: treeController, children: children)
		}
	}
}

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
	typealias View = AccountsViewController
	typealias Interactor = AccountsInteractor
	typealias Presentation = [AnyTreeItem]
	
	weak var view: View!
	lazy var interactor: Interactor! = Interactor(presenter: self)
	
	var content: Interactor.Content?
	var presentation: Presentation?
	var loading: Future<Presentation>?
	
	required init(view: View) {
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
	
	func presentation(for content: Interactor.Content) -> Future<Presentation> {
		let folders = Tree.Item.AccountFoldersResultsController(context: Services.storage.viewContext, treeController: view.treeController, cachePolicy: content)
		let defaultFolder = Tree.Item.AccountsDefaultFolder(treeController: view.treeController, cachePolicy: content)
		return .init([defaultFolder.asAnyItem, folders.asAnyItem])
	}
	
	func onPan(_ sender: UIPanGestureRecognizer) {
		if sender.state == .began && sender.translation(in: view.view).y < 0 {
			view.unwinder?.unwind()
		}
	}

	func canEdit<T: TreeItem>(_ item: T) -> Bool {
		return item is Tree.Item.AccountsItem
	}
	
	func editingStyle<T: TreeItem>(for item: T) -> UITableViewCell.EditingStyle {
		return item is Tree.Item.AccountsItem ? .delete : .none
	}
	
	func commit<T: TreeItem>(editingStyle: UITableViewCell.EditingStyle, for item: T) {
		
	}
}

extension Tree.Item {
	
	class AccountFoldersResultsController: FetchedResultsController<FetchedResultsSection<AccountsFolderItem>> {
		var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
		
		convenience init(context: StorageContext, treeController: TreeController?, cachePolicy: URLRequest.CachePolicy) {
			let fetchRequest = context.managedObjectContext.from(AccountsFolder.self).sort(by: \AccountsFolder.name, ascending: true).fetchRequest
			let frc = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: context.managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
			self.init(frc, treeController: treeController)
			self.cachePolicy = cachePolicy
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
			return [AccountsResultsController(frc, treeController: section.controller.treeController, cachePolicy: (section.controller as! AccountFoldersResultsController).cachePolicy)]
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
		var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
		
		convenience init(_ fetchedResultsController: NSFetchedResultsController<Account>, treeController: TreeController?, cachePolicy: URLRequest.CachePolicy) {
			self.init(fetchedResultsController, diffIdentifier: fetchedResultsController.fetchRequest, treeController: treeController)
			self.cachePolicy = cachePolicy
		}
	}
	
	class AccountsDefaultFolder: Tree.Item.Section<AccountsResultsController> {
		var cachePolicy: URLRequest.CachePolicy
		
		init(treeController: TreeController?, cachePolicy: URLRequest.CachePolicy) {
			self.cachePolicy = cachePolicy
			
			let managedObjectContext = Services.storage.viewContext.managedObjectContext
			
			let request = managedObjectContext.from(Account.self)
				.filter(\Account.folder == nil)
				.sort(by: \Account.folder, ascending: true).sort(by: \Account.characterName, ascending: true)
				.fetchRequest
			
			let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
			let children = [AccountsResultsController(frc, treeController: treeController, cachePolicy: cachePolicy)]

			super.init(Tree.Content.Section(title: "Default"), diffIdentifier: "defaultFolder", expandIdentifier: "defaultFolder", treeController: treeController, children: children)
		}
	}
}

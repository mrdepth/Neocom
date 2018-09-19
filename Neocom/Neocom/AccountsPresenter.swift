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
								 Prototype.AccountCell.default,
								 Prototype.TreeHeaderCell.editingAction])

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
		return item is Tree.Item.AccountsItem || item is Tree.Item.AccountsFolderItem
	}
	
	func editingStyle<T: TreeItem>(for item: T) -> UITableViewCell.EditingStyle {
		return item is Tree.Item.AccountsItem || item is Tree.Item.AccountsFolderItem ? .delete : .none
	}
	
	func editActions<T: TreeItem>(for item: T) -> [UITableViewRowAction]? {
		switch item {
		case let item as Tree.Item.AccountsItem:
			return [UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { (_, _) in
				item.result.managedObjectContext?.delete(item.result)
				if item.result.managedObjectContext?.hasChanges == true {
					try? item.result.managedObjectContext?.save()
				}
			})]
		case let item as Tree.Item.AccountsFolderItem:
			return [
				UITableViewRowAction(style: .destructive, title: NSLocalizedString("Delete", comment: ""), handler: { (_, _) in
					item.result.managedObjectContext?.delete(item.result)
					if item.result.managedObjectContext?.hasChanges == true {
						try? item.result.managedObjectContext?.save()
					}
				}),
				UITableViewRowAction(style: .normal, title: NSLocalizedString("Rename", comment: ""), handler: { [weak self] (_, _) in
					self?.performRename(folder: item.result)
				})
			]
		default:
			return nil
		}
	}
	
	func commit<T: TreeItem>(editingStyle: UITableViewCell.EditingStyle, for item: T) {
	}
	
	func canMove<T: TreeItem>(_ item: T) -> Bool {
		return item is Tree.Item.AccountsItem
	}

	func canMove<T: TreeItem, S: TreeItem, D: TreeItem>(_ item: T, at fromIndex: Int, inParent oldParent: S?, to toIndex: Int, inParent newParent: D?) -> Bool {
		return item is Tree.Item.AccountsItem && newParent is Tree.Item.FetchedResultsSection<Tree.Item.AccountsItem>
	}

	func move<T: TreeItem, S: TreeItem, D: TreeItem>(_ item: T, at fromIndex: Int, inParent oldParent: S?, to toIndex: Int, inParent newParent: D?) {
		if let accountItem = item as? Tree.Item.AccountsItem, let section = newParent as? Tree.Item.FetchedResultsSection<Tree.Item.AccountsItem> {
			accountItem.result.folder = (section.controller as? Tree.Item.AccountsResultsController)?.folder
			try? Services.storage.viewContext.save()
		}
	}

	func onNewFolder() {
		let controller = UIAlertController(title: NSLocalizedString("Enter Folder Name", comment: ""), message: nil, preferredStyle: .alert)
		
		var textField: UITextField?
		
		controller.addTextField(configurationHandler: {
			textField = $0
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Add Folder", comment: ""), style: .default, handler: { (action) in
			_ = Services.storage.viewContext.newFolder(named: textField?.text ?? "")
			try? Services.storage.viewContext.save()
		}))
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		view.present(controller, animated: true, completion: nil)
	}
	
	func onFolderActions(_ folder: AccountsFolder) {
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { [weak self] (_) in
			self?.performRename(folder: folder)
		}))
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Delete", comment: ""), style: .destructive, handler: { (_) in
			folder.managedObjectContext?.delete(folder)
			if folder.managedObjectContext?.hasChanges == true {
				try? folder.managedObjectContext?.save()
			}
		}))

		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: { (_) in
			
		}))

		view.present(controller, animated: true, completion: nil)
	}
	
	func didSelect<T: TreeItem>(item: T) -> Void {
		guard !view.isEditing else {return}
		guard let item = item as? Tree.Item.AccountsItem else {return}
		Services.storage.viewContext.setCurrentAccount(item.result)
		view.unwinder?.unwind()
	}
	
	func onDelete(items: [NSManagedObject]) -> Future<Void> {
		guard !items.isEmpty else {return .init(())}
		let promise = Promise<Void>()
		
		let controller = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
		controller.addAction(UIAlertAction(title: String.localizedStringWithFormat(NSLocalizedString("Delete %d Items", comment: ""), items.count), style: .destructive) { _ in
			items.forEach {
				$0.managedObjectContext?.delete($0)
			}
			if let context = items.first?.managedObjectContext, context.hasChanges {
				try? context.save()
			}
			try? promise.fulfill(())
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel) { _ in
			try? promise.fail(NCError.cancelled(type: AccountsPresenter.self, function: #function))
		})
		
		view.present(controller, animated: true, completion: nil)
		controller.popoverPresentationController?.barButtonItem = view.toolbarItems?.last
		
		return promise.future
	}
	
	private func performRename(folder: AccountsFolder) {
		let controller = UIAlertController(title: NSLocalizedString("Rename", comment: ""), message: nil, preferredStyle: .alert)
		
		var textField: UITextField?
		
		controller.addTextField(configurationHandler: {
			textField = $0
			textField?.text = folder.name
			textField?.clearButtonMode = .always
		})
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Rename", comment: ""), style: .default, handler: { (action) in
			if textField?.text?.isEmpty == false && folder.name != textField?.text {
				folder.name = textField?.text
				if folder.managedObjectContext?.hasChanges == true {
					try? folder.managedObjectContext?.save()
				}
			}
		}))
		
		controller.addAction(UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil))
		
		view.present(controller, animated: true, completion: nil)
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
		weak var section: FetchedResultsSectionProtocol?
		
		private lazy var _children: [AccountsResultsController]? = {
			let request = result.managedObjectContext!.from(Account.self)
				.filter(\Account.folder == result)
				.sort(by: \Account.order, ascending: true).sort(by: \Account.characterName, ascending: true)
				.fetchRequest
			
			let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: result.managedObjectContext!, sectionNameKeyPath: nil, cacheName: nil)
			return [AccountsResultsController(frc, treeController: section?.controller?.treeController, cachePolicy: (section?.controller as? AccountFoldersResultsController)?.cachePolicy ?? .useProtocolCachePolicy, folder: result)]
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
			super.init(Tree.Content.Section(prototype: Prototype.TreeHeaderCell.editingAction, title: result.name?.uppercased()), diffIdentifier: result, expandIdentifier: result.objectID, treeController: section.controller?.treeController)
		}
	}
	
	class AccountsResultsController: FetchedResultsController<FetchedResultsSection<AccountsItem>> {
		var cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy
		var folder: AccountsFolder?
		
		convenience init(_ fetchedResultsController: NSFetchedResultsController<Account>, treeController: TreeController?, cachePolicy: URLRequest.CachePolicy, folder: AccountsFolder?) {
			self.init(fetchedResultsController, diffIdentifier: fetchedResultsController.fetchRequest, treeController: treeController)
			self.cachePolicy = cachePolicy
			self.folder = folder
		}
	}
	
	class AccountsDefaultFolder: Tree.Item.Section<AccountsResultsController> {
		var cachePolicy: URLRequest.CachePolicy
		
		init(treeController: TreeController?, cachePolicy: URLRequest.CachePolicy) {
			self.cachePolicy = cachePolicy
			
			let managedObjectContext = Services.storage.viewContext.managedObjectContext
			
			let request = managedObjectContext.from(Account.self)
				.filter(\Account.folder == nil)
				.sort(by: \Account.order, ascending: true).sort(by: \Account.characterName, ascending: true)
				.fetchRequest
			
			let frc = NSFetchedResultsController(fetchRequest: request, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil)
			let children = [AccountsResultsController(frc, treeController: treeController, cachePolicy: cachePolicy, folder: nil)]
			
			super.init(Tree.Content.Section(title: NSLocalizedString("Default", comment: "Folder Name").uppercased()), diffIdentifier: "defaultFolder", expandIdentifier: "defaultFolder", treeController: treeController, children: children)
		}
	}
}

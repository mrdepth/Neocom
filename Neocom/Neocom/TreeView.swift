//
//  TreeView.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

extension TreeController {
	func reload<T: TreeItem>(_ content: [T], options: BatchUpdateOptions = [], with animation: TreeController.RowAnimation = .none) -> Future<Void> {
		let promise = Promise<Void>()
		reload(content, options: options, with: animation) {
			try? promise.fulfill(())
		}
		return promise.future
	}
}

protocol TreeView: View, TreeControllerDelegate where P: TreePresenter {
	var tableView: UITableView! {get}
	var treeController: TreeController! {get}
}

protocol TreePresenter: Presenter where V: TreeView, I: TreeInteractor {
	associatedtype Item: TreeItem
	var content: I.Content? {get set}
	
	func reload(cachePolicy: URLRequest.CachePolicy) -> Future<Void>
	func presentation(for content: I.Content) -> Future<[Item]>
	func didChange(content: I.Content) -> Void
	func applicationWillEnterForeground() -> Void
	
	func isItemExpandable<T: TreeItem>(_ item: T) -> Bool
	func isItemExpanded<T: TreeItem>(_ item: T) -> Bool
	func didExpand<T: TreeItem>(item: T) -> Void
	func didCollapse<T: TreeItem>(item: T) -> Void
}

protocol TreeInteractor: Interactor where P: TreePresenter {
	associatedtype Content = Void
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Content>
	func isExpired(_ content: Content) -> Bool
}

extension TreeView {
	
	func treeController<T: TreeItem> (_ treeController: TreeController, cellIdentifierFor item: T) -> String? {
		if let item = item as? CellConfiguring {
			return item.cellIdentifier
		}
		else {
			return nil
		}
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, configure cell: UITableViewCell, for item: T) -> Void {
		if let item = item as? CellConfiguring {
			return item.configure(cell: cell)
		}
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, didSelectRowFor item: T) -> Void {
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, didDeselectRowFor item: T) -> Void {
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, isExpandable item: T) -> Bool {
		return presenter.isItemExpandable(item)
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, isExpanded item: T) -> Bool {
		return presenter.isItemExpanded(item)
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, didExpand item: T) -> Void {
		presenter.didExpand(item: item)
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, didCollapse item: T) -> Void {
		presenter.didCollapse(item: item)
	}
}

extension TreePresenter {
	
	func reload(cachePolicy: URLRequest.CachePolicy) -> Future<Void> {
		return interactor.load(cachePolicy: cachePolicy).then { [weak self] content -> Future<Void> in
			guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
			return strongSelf.presentation(for: content).then(on: .main) { presentation -> Future<Void> in
				guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
				strongSelf.content = content
				return strongSelf.view.treeController.reload(presentation)
			}
		}
	}
	
	func didChange(content: I.Content) -> Void {
		self.presentation(for: content).then(on: .main) { [weak self] presentation -> Future<Void> in
			guard let strongSelf = self else {throw NCError.cancelled(type: type(of: self), function: #function)}
			strongSelf.content = content
			return strongSelf.view.treeController.reload(presentation)
		}
	}
	
	func isItemExpandable<T: TreeItem>(_ item: T) -> Bool {
		return item is ExpandableItem
	}
	
	func isItemExpanded<T: TreeItem>(_ item: T) -> Bool {
		if let item = item as? ExpandableItem ?? (item as? AnyTreeItem)?.base as? ExpandableItem {
			if let identifier = item.expandIdentifier?.description,
				let state = interactor.cache.viewContext.sectionCollapseState(identifier: identifier, scope: V.self) {
				return state.isExpanded
			}
			else {
				return item.initiallyExpanded
			}
		}
		else {
			return true
		}
	}
	
	func didExpand<T: TreeItem>(item: T) {
		if let item = item as? ExpandableItem ?? (item as? AnyTreeItem)?.base as? ExpandableItem,
			let identifier = item.expandIdentifier?.description {
			let state = interactor.cache.viewContext.sectionCollapseState(identifier: identifier, scope: V.self) ??
				interactor.cache.viewContext.newSectionCollapseState(identifier: identifier, scope: V.self)
			state.isExpanded = true
		}

	}
	
	func didCollapse<T: TreeItem>(item: T) {
		if let item = item as? ExpandableItem ?? (item as? AnyTreeItem)?.base as? ExpandableItem,
			let identifier = item.expandIdentifier?.description {
			let state = interactor.cache.viewContext.sectionCollapseState(identifier: identifier, scope: V.self) ??
				interactor.cache.viewContext.newSectionCollapseState(identifier: identifier, scope: V.self)
			state.isExpanded = false
		}
	}
}

extension TreeInteractor {
	func api(cachePolicy: URLRequest.CachePolicy) -> API {
		return APIClient(account: storage.viewContext.currentAccount(), cachePolicy: cachePolicy, cache: cache, sde: sde)
	}
}

extension TreePresenter where I.Content == Void {
	var content: Void? {
		get { return nil}
		set {}
	}
}

extension TreeInteractor where Content == Void {
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<Void> {
		return .init(())
	}
}

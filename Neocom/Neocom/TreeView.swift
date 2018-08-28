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

protocol TreeView: ContentProviderView, TreeControllerDelegate where Presenter: TreePresenter {
	var tableView: UITableView! {get}
	var treeController: TreeController! {get}
}

protocol TreePresenter: ContentProviderPresenter where View: TreeView, Interactor: TreeInteractor, Presentation == [Item] {
	associatedtype Item: TreeItem
	func isItemExpandable<T: TreeItem>(_ item: T) -> Bool
	func isItemExpanded<T: TreeItem>(_ item: T) -> Bool
	func didExpand<T: TreeItem>(item: T) -> Void
	func didCollapse<T: TreeItem>(item: T) -> Void
}

protocol TreeInteractor: ContentProviderInteractor where Presenter: TreePresenter {
}

extension TreeView {
	func present(_ content: Presenter.Presentation) -> Future<Void> {
		tableView.backgroundView = nil
		return treeController.reload(content)
	}
	
	func fail(_ error: Error) -> Void {
		tableView.backgroundView = TableViewBackgroundLabel(error: error)
	}

	func treeController<T: TreeItem> (_ treeController: TreeController, cellIdentifierFor item: T) -> String? {
		if let item = item as? CellConfiguring ?? (item as? AnyTreeItem)?.base as? CellConfiguring {
			return item.cellIdentifier
		}
		else {
			return nil
		}
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, configure cell: UITableViewCell, for item: T) -> Void {
		if let item = item as? CellConfiguring ?? (item as? AnyTreeItem)?.base as? CellConfiguring {
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

	func isItemExpandable<T: TreeItem>(_ item: T) -> Bool {
		return item is ExpandableItem || (item as? AnyTreeItem)?.base is ExpandableItem
	}
	
	func isItemExpanded<T: TreeItem>(_ item: T) -> Bool {
		if let item = item as? ExpandableItem ?? (item as? AnyTreeItem)?.base as? ExpandableItem {
			if let identifier = item.expandIdentifier?.description,
				let state = interactor.cache.viewContext.sectionCollapseState(identifier: identifier, scope: View.self) {
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
		if var item = item as? ExpandableItem ?? (item as? AnyTreeItem)?.base as? ExpandableItem,
			let identifier = item.expandIdentifier?.description {
			let state = interactor.cache.viewContext.sectionCollapseState(identifier: identifier, scope: View.self) ??
				interactor.cache.viewContext.newSectionCollapseState(identifier: identifier, scope: View.self)
			state.isExpanded = true
			item.isExpanded = true
		}

	}
	
	func didCollapse<T: TreeItem>(item: T) {
		if var item = item as? ExpandableItem ?? (item as? AnyTreeItem)?.base as? ExpandableItem,
			let identifier = item.expandIdentifier?.description {
			let state = interactor.cache.viewContext.sectionCollapseState(identifier: identifier, scope: View.self) ??
				interactor.cache.viewContext.newSectionCollapseState(identifier: identifier, scope: View.self)
			state.isExpanded = false
			item.isExpanded = false
		}
	}
}


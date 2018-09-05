//
//  TreeViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 24.08.2018.
//  Copyright © 2018 Artem Shimanski. All rights reserved.
//

import Foundation
import TreeController
import Futures

protocol TreeView: ContentProviderView, TreeControllerDelegate where Presenter: TreePresenter {
	var tableView: UITableView! {get}
	var treeController: TreeController! {get}
}

protocol TreePresenter: ContentProviderPresenter where View: TreeView, Interactor: TreeInteractor {
	func isItemExpandable<T: TreeItem>(_ item: T) -> Bool
	func isItemExpanded<T: TreeItem>(_ item: T) -> Bool
	func didExpand<T: TreeItem>(item: T) -> Void
	func didCollapse<T: TreeItem>(item: T) -> Void
}

protocol TreeInteractor: ContentProviderInteractor where Presenter: TreePresenter {
}


class TreeViewController<Presenter: TreePresenter>: UITableViewController, View, TreeControllerDelegate {
	lazy var presenter: Presenter! = Presenter(view: self as! Presenter.View)
	var unwinder: Unwinder?
	lazy var treeController: TreeController! = TreeController()
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.delegate = self
		treeController.scrollViewDelegate = self
		treeController.tableView = tableView
		presenter.configure()
		
		if let refreshControl = refreshControl {
			refreshHandler = ActionHandler(refreshControl, for: .valueChanged) { [weak self] (control) in
				if self?.tableView.isDragging == true {
					self?.shouldReload = true
				}
				else {
					self?.reload()
				}
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		presenter.viewWillAppear(animated)
	}
	
	override func viewDidAppear(_ animated: Bool) {
		super.viewDidAppear(animated)
		presenter.viewDidAppear(animated)
	}
	
	override func viewWillDisappear(_ animated: Bool) {
		super.viewWillDisappear(animated)
		presenter.viewWillDisappear(animated)
	}
	
	override func viewDidDisappear(_ animated: Bool) {
		super.viewDidDisappear(animated)
		presenter.viewDidDisappear(animated)
	}
	
	func fail(_ error: Error) -> Void {
		tableView.backgroundView = TableViewBackgroundLabel(error: error)
	}

	func treeController<T: TreeItem> (_ treeController: TreeController, cellIdentifierFor item: T) -> String? {
		if let item = item as? CellConfiguring ?? (item as? AnyTreeItem)?.base as? CellConfiguring {
			return item.prototype?.reuseIdentifier
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
	
	override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		if shouldReload {
			shouldReload = false
			reload()
		}
	}
	
	private var refreshHandler: ActionHandler<UIRefreshControl>?
	private var shouldReload = false
	private func reload() {
		presenter.reload(cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, animated: true).finally(on: .main) { [weak self] in
			DispatchQueue.main.async {
				self?.refreshControl?.endRefreshing()
			}
		}
	}
}

extension TreeController {
	func reloadData<T: Collection>(_ data: T, options: BatchUpdateOptions = [], with animation: TreeController.RowAnimation = .none) -> Future<Void> where T.Element: TreeItem {
		let promise = Promise<Void>()
		reloadData(data, options: options, with: animation) {
			try? promise.fulfill(())
		}
		return promise.future
	}
	
	func reloadData<T: TreeItem>(from item: T, options: BatchUpdateOptions = [], with animation: TreeController.RowAnimation = .none)  -> Future<Void> {
		let promise = Promise<Void>()
		reloadData(from: item, options: options, with: animation) {
			try? promise.fulfill(())
		}
		return promise.future
	}
}



extension TreeView where Presenter.Presentation: Collection, Presenter.Presentation.Element: TreeItem {
	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void> {
		tableView.backgroundView = nil
		return treeController.reloadData(content, with: animated ? .automatic : .none)
	}
}

extension TreeView where Presenter.Presentation: TreeItem {
	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void> {
		tableView.backgroundView = nil
		return treeController.reloadData(from: content, with: animated ? .automatic : .none)
	}
}

extension TreePresenter {

	func isItemExpandable<T: TreeItem>(_ item: T) -> Bool {
		return item is ExpandableItem || (item as? AnyTreeItem)?.base is ExpandableItem
	}
	
	func isItemExpanded<T: TreeItem>(_ item: T) -> Bool {
		if let item = item as? ExpandableItem ?? (item as? AnyTreeItem)?.base as? ExpandableItem {
			if let identifier = item.expandIdentifier?.description,
				let state = Services.cache.viewContext.sectionCollapseState(identifier: identifier, scope: View.self) {
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
			let state = Services.cache.viewContext.sectionCollapseState(identifier: identifier, scope: View.self) ??
				Services.cache.viewContext.newSectionCollapseState(identifier: identifier, scope: View.self)
			state.isExpanded = true
			item.isExpanded = true
		}

	}
	
	func didCollapse<T: TreeItem>(item: T) {
		if var item = item as? ExpandableItem ?? (item as? AnyTreeItem)?.base as? ExpandableItem,
			let identifier = item.expandIdentifier?.description {
			let state = Services.cache.viewContext.sectionCollapseState(identifier: identifier, scope: View.self) ??
				Services.cache.viewContext.newSectionCollapseState(identifier: identifier, scope: View.self)
			state.isExpanded = false
			item.isExpanded = false
		}
	}
}


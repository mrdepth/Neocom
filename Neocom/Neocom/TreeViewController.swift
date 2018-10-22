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
import CloudData

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

protocol SearchableViewController {
	func searchResultsController() -> UIViewController & UISearchResultsUpdating
}

class TreeViewController<Presenter: TreePresenter, Input>: UITableViewController, View, TreeControllerDelegate {
	lazy var presenter: Presenter! = Presenter(view: self as! Presenter.View)
	var unwinder: Unwinder?
	var input: Input?
	lazy var treeController: TreeController! = TreeController()
	
	var searchController: UISearchController?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		treeController.delegate = self
		treeController.scrollViewDelegate = self
		treeController.tableView = tableView
		presenter.configure()
		
		if let refreshControl = refreshControl {
			refreshHandler = ActionHandler(refreshControl, for: .valueChanged) { [weak self] (control) in
				self?.reload()
			}
		}
		
	}
	
	override func willMove(toParent parent: UIViewController?) {
		super.willMove(toParent: parent)
		guard !(parent is UISearchController) else {return}
		if let `self` = (self as? SearchableViewController) {
			let searchResultsController = self.searchResultsController()
			searchController = UISearchController(searchResultsController: searchResultsController)
			searchController?.searchBar.searchBarStyle = .default
			searchController?.searchResultsUpdater = searchResultsController
			searchController?.searchBar.barStyle = .black
			searchController?.searchBar.isTranslucent = false
			searchController?.hidesNavigationBarDuringPresentation = false
			tableView.backgroundView = UIView()
			tableView.tableHeaderView = searchController?.searchBar
			definesPresentationContext = true
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
		if case NCError.reloadInProgress = error {
			
		}
		else {
			presenter.presentation = nil
			_ = treeController.reloadData([] as [AnyTreeItem])
			tableView.backgroundView = TableViewBackgroundLabel(error: error)
		}
	}

	func treeController<T: TreeItem> (_ treeController: TreeController, cellIdentifierFor item: T) -> String? {
		if let item = item as? CellConfiguring {
			return item.prototype?.reuseIdentifier
		}
		else {
			return nil
		}
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, configure cell: UITableViewCell, for item: T) -> Void {
		cell.indentationLevel = treeController.indentationLevel(for: item)
		if let item = item as? CellConfiguring {
			return item.configure(cell: cell)
		}
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, didSelectRowFor item: T) -> Void {
		guard !isEditing else {return}
		guard let route = (item as? Routable)?.route else {return}
		_ = route.perform(from: self)
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
	
	func treeController<T>(_ treeController: TreeController, canEdit item: T) -> Bool where T : TreeItem {
		return false
	}
	
	func treeController<T>(_ treeController: TreeController, editingStyleFor item: T) -> UITableViewCell.EditingStyle where T : TreeItem {
		return .none
	}
	
	func treeController<T>(_ treeController: TreeController, commit editingStyle: UITableViewCell.EditingStyle, for item: T) where T : TreeItem {
	}

	func treeController<T: TreeItem> (_ treeController: TreeController, editActionsFor item: T) -> [UITableViewRowAction]? {
		return nil
	}
	
	func treeController<T: TreeItem> (_ treeController: TreeController, accessoryButtonTappedFor item: T) -> Void {
	}

	func treeController<T: TreeItem> (_ treeController: TreeController, canMove item: T) -> Bool {
		return false
	}
	
	func treeController<T: TreeItem, S: TreeItem, D: TreeItem> (_ treeController: TreeController, canMove item: T, at fromIndex: Int, inParent oldParent: S?, to toIndex: Int, inParent newParent: D?) -> Bool {
		return false
	}
	
	func treeController<T: TreeItem, S: TreeItem, D: TreeItem> (_ treeController: TreeController, move item: T, at fromIndex: Int, inParent oldParent: S?, to toIndex: Int, inParent newParent: D?) -> Void {
		
	}

	
	override func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
		guard !decelerate else {return}
		if let presentation = pendingPresentation {
			self.pendingPresentation = nil
			DispatchQueue.main.async {
				self.presenter.view?.present(presentation, animated: true)
			}
		}
		if refreshControl?.isRefreshing == true && presenter.loading == nil {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				self.refreshControl?.endRefreshing()
			}
		}
	}
	
	override func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
		if let presentation = pendingPresentation {
			self.pendingPresentation = nil
			DispatchQueue.main.async {
				self.presenter.view?.present(presentation, animated: true)
			}
		}
		if refreshControl?.isRefreshing == true && presenter.loading == nil {
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
				self.refreshControl?.endRefreshing()
			}
		}
	}
	
	private var refreshHandler: ActionHandler<UIRefreshControl>?
	private var pendingPresentation: Presenter.Presentation?
	private func reload() {
		presenter.reload(cachePolicy: .reloadIgnoringLocalAndRemoteCacheData).then(on: .main) { [weak self] presentation in
			guard let strongSelf = self else {return}
			if strongSelf.tableView.isDragging {
				self?.pendingPresentation = presentation
			}
			else {
				strongSelf.presenter.view?.present(presentation, animated: true)
			}
		}.catch(on: .main) { [weak self] error in
			self?.presenter.view?.fail(error)
		}.finally(on: .main) { [weak self] in
			guard let strongSelf = self else {return}
			if !strongSelf.tableView.isDragging && strongSelf.refreshControl?.isRefreshing == true {
				DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
					strongSelf.refreshControl?.endRefreshing()
				}
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
	@discardableResult
	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void> {
		tableView.backgroundView = nil
		return treeController.reloadData(content, with: animated ? .automatic : .none)
	}
}

extension TreeView where Presenter.Presentation: TreeItem {
	@discardableResult
	func present(_ content: Presenter.Presentation, animated: Bool) -> Future<Void> {
		tableView.backgroundView = nil
		return treeController.reloadData(from: content, with: animated ? .automatic : .none)
	}
}

extension TreePresenter {

	func isItemExpandable<T: TreeItem>(_ item: T) -> Bool {
		return item is ExpandableItem
	}
	
	func isItemExpanded<T: TreeItem>(_ item: T) -> Bool {
		if let item = item as? ExpandableItem {
			if let identifier = item.expandIdentifier?.description,
				let state = Services.cache.viewContext.sectionCollapseState(identifier: identifier, scope: View.self) {
				return state.isExpanded
			}
			else {
				return item.isExpanded
			}
		}
		else {
			return true
		}
	}
	
	func didExpand<T: TreeItem>(item: T) {
		guard var item = item as? ExpandableItem else {return}
		if let identifier = item.expandIdentifier?.description {
			let state = Services.cache.viewContext.sectionCollapseState(identifier: identifier, scope: View.self) ??
				Services.cache.viewContext.newSectionCollapseState(identifier: identifier, scope: View.self)
			state.isExpanded = true
		}
		item.isExpanded = true
	}
	
	func didCollapse<T: TreeItem>(item: T) {
		guard var item = item as? ExpandableItem else {return}
		if let identifier = item.expandIdentifier?.description {
			let state = Services.cache.viewContext.sectionCollapseState(identifier: identifier, scope: View.self) ??
				Services.cache.viewContext.newSectionCollapseState(identifier: identifier, scope: View.self)
			state.isExpanded = false
		}
		item.isExpanded = false
	}
}

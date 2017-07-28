//
//  NCTreeViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 07.07.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import CloudData

protocol NCSearchableViewController: UISearchResultsUpdating {
	var searchController: UISearchController? {get set}
}

extension NCSearchableViewController {
	func setupSearchController(searchResultsController: UIViewController) {
		guard let controller = self as? UITableViewController else {return}
		searchController = UISearchController(searchResultsController: searchResultsController)
		searchController?.searchBar.searchBarStyle = UISearchBarStyle.default
		searchController?.searchResultsUpdater = self
		searchController?.searchBar.barStyle = UIBarStyle.black
		searchController?.hidesNavigationBarDuringPresentation = false
		controller.tableView.backgroundView = UIView()
		controller.tableView.tableHeaderView = searchController?.searchBar
		controller.definesPresentationContext = true
		
	}
}

class NCTreeViewController: UITableViewController, TreeControllerDelegate {
	var treeController: TreeController?
	
	
	private var accountChangeObserver: NotificationObserver?
	var needsReloadOnAccountChange: Bool = false {
		didSet {
			accountChangeObserver = nil
			if needsReloadOnAccountChange {
				accountChangeObserver = NotificationCenter.default.addNotificationObserver(forName: .NCCurrentAccountChanged, object: nil, queue: nil) { [weak self] _ in
					self?.reload()
				}
			}
		}
	}
	
	private var becomeActiveObserver: NotificationObserver?
	
	override func viewDidLoad() {
		super.viewDidLoad()
		tableView.backgroundColor = UIColor.background
		tableView.estimatedRowHeight = tableView.rowHeight
		tableView.rowHeight = UITableViewAutomaticDimension
		
		treeController = TreeController()
		treeController?.delegate = self
		treeController?.tableView = tableView
		
		tableView.delegate = treeController
		tableView.dataSource = treeController
		
		if let refreshControl = refreshControl {
			refreshHandler = NCActionHandler(refreshControl, for: .valueChanged) { [weak self] _ in
				self?.reload(cachePolicy: .reloadIgnoringLocalCacheData)
			}
		}
		
		becomeActiveObserver = NotificationCenter.default.addNotificationObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] _ in
			guard let strongSelf = self else {return}
			if strongSelf.treeController?.content == nil || (strongSelf.expireDate ?? Date.distantFuture) < Date() {
				strongSelf.reload()
			}
		}
	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		if treeController?.content == nil || (expireDate ?? Date.distantFuture) < Date() {
			reload()
		}
	}
	
	private var refreshHandler: NCActionHandler?
	
	func reload() {
		self.reload(cachePolicy: .useProtocolCachePolicy)
	}

	var isLoading: Bool = false
	lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	
	func updateContent(completionHandler: @escaping () -> Void) {
		completionHandler()
	}
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void ) {
		completionHandler([])
	}
	
	private var managedObjectsObserver: NCManagedObjectObserver?
	lazy var updateGate = NCGate()
	
	@objc private func delayedUpdate() {
		let date = Date()
		expireDate = managedObjectsObserver?.objects.flatMap {($0 as? NCCacheRecord)?.expireDate as Date?}.filter {$0 > date}.min()
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
		updateGate.perform {
			let group = DispatchGroup()
			group.enter()
			DispatchQueue.main.async {
				progress.progress.perform {
					self.updateContent {
						progress.finish()
						group.leave()
					}
				}
			}
			group.wait()
		}

	}
	
	var expireDate: Date?
	
	@nonobjc private func reload(cachePolicy: URLRequest.CachePolicy) {
		guard !isLoading else {return}
		
		guard !needsReloadOnAccountChange || dataManager.account != nil else {
			treeController?.content = nil
			tableView.backgroundView = NCTableViewBackgroundLabel(text: NSLocalizedString("Please Sign In", comment: ""))
			return
		}
		
		isLoading = true
		
		dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		managedObjectsObserver = nil

		let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
		progress.progress.perform {
			self.reload(cachePolicy: cachePolicy) { [weak self] records in
				guard let strongSelf = self else {
					progress.finish()
					return
				}
				
				let date = Date()
				strongSelf.expireDate = records.flatMap {$0.expireDate as Date?}.filter {$0 > date}.min()

				progress.progress.perform {
					strongSelf.updateContent {
						progress.finish()
						strongSelf.isLoading = false
						if let refreshControl = strongSelf.refreshControl, refreshControl.isRefreshing {
							refreshControl.endRefreshing()
						}
					}
				}
				strongSelf.managedObjectsObserver = NCManagedObjectObserver(managedObjects: records) { [weak self] _ in
					guard let strongSelf = self else {return}
					NSObject.cancelPreviousPerformRequests(withTarget: strongSelf, selector: #selector(NCTreeViewController.delayedUpdate), object: nil)
					strongSelf.perform(#selector(NCTreeViewController.delayedUpdate), with: nil, afterDelay: 0)
				}
			}
		}
	}
	
	//MARK: - TreeControllerDelegate
	
	func treeController(_ treeController: TreeController, didSelectCellWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.route {
			route.perform(source: self, view: treeController.cell(for: node))
		}
		treeController.deselectCell(for: node, animated: true)
	}
	
	func treeController(_ treeController: TreeController, accessoryButtonTappedWithNode node: TreeNode) {
		if let route = (node as? TreeNodeRoutable)?.accessoryButtonRoute {
			route.perform(source: self, view: treeController.cell(for: node))
		}
	}
	
}

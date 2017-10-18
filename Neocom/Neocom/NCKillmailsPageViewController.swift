//
//  NCKillmailsPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI
import CloudData

class NCDateSection: TreeSection {
	let date: Date
	let doesRelativeDateFormatting: Bool
	init(date: Date, doesRelativeDateFormatting: Bool = true) {
		self.date = date
		self.doesRelativeDateFormatting = doesRelativeDateFormatting
		super.init(prototype: Prototype.NCHeaderTableViewCell.default)
	}
	
	lazy var title: String = {
		let formatter = DateFormatter()
		formatter.doesRelativeDateFormatting = self.doesRelativeDateFormatting
		formatter.timeStyle = .none
		formatter.dateStyle = .medium
		return formatter.string(from: self.date)
	}()
	
	override func configure(cell: UITableViewCell) {
		guard let cell = cell as? NCHeaderTableViewCell else {return}
		cell.titleLabel?.text = self.title.uppercased()
	}
}


class NCKillmailsPageViewController: NCPageViewController, NCAPIController {
	
	var killsViewController: NCKillmailsViewController?
	var lossesViewController: NCKillmailsViewController?
	
	var accountChangeObserver: NotificationObserver?
	var becomeActiveObserver: NotificationObserver?

	override func viewDidLoad() {
		super.viewDidLoad()
		accountChangeAction = .reload

		killsViewController = storyboard!.instantiateViewController(withIdentifier: "NCKillmailsViewController") as? NCKillmailsViewController
		killsViewController?.title = NSLocalizedString("Kills", comment: "")
		lossesViewController = storyboard!.instantiateViewController(withIdentifier: "NCKillmailsViewController") as? NCKillmailsViewController
		lossesViewController?.title = NSLocalizedString("Losses", comment: "")
		
		viewControllers = [killsViewController!, lossesViewController!]
		
		becomeActiveObserver = NotificationCenter.default.addNotificationObserver(forName: .UIApplicationDidBecomeActive, object: nil, queue: nil) { [weak self] _ in
			self?.reloadIfNeeded()
		}

	}
	
	override func viewWillAppear(_ animated: Bool) {
		super.viewWillAppear(animated)
		reloadIfNeeded()
	}
	
	private(set) var isFetching = false
	
	func fetchIfNeeded() {
		guard let tableView = (currentPage as? NCKillmailsViewController)?.tableView else {return}
		if let lastID = lastID, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			guard !isEndReached, !isFetching else {return}

			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			progress.progress.perform {
				fetch(from: lastID) { _ in
					progress.finish()
				}
			}
		}
		
	}
	
	//MAKR: - NCAPIController
	
	var accountChangeAction: AccountChangeAction = .none {
		didSet {
			switch accountChangeAction {
			case .none:
				accountChangeObserver = nil
			case .reload:
				accountChangeObserver = NotificationCenter.default.addNotificationObserver(forName: .NCCurrentAccountChanged, object: nil, queue: nil) { [weak self] _ in
					self?.reload()
				}
			case .update:
				accountChangeObserver = NotificationCenter.default.addNotificationObserver(forName: .NCCurrentAccountChanged, object: nil, queue: nil) { [weak self] _ in
					self?.updateContent {
					}
				}
			}
		}
	}
	
	var isLoading: Bool = false
	lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	
	func updateContent(completionHandler: @escaping () -> Void) {
		kills = TreeNode()
		losses = TreeNode()
		update(result: result, completionHandler: completionHandler)
	}
	
	func reload(cachePolicy: URLRequest.CachePolicy, completionHandler: @escaping ([NCCacheRecord]) -> Void ) {
		lastID = nil
		isEndReached = false
		kills = nil
		losses = nil
		self.dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		fetch(from: nil) { result in
			completionHandler([result.cacheRecord].flatMap {$0})
		}
	}
	
	func didStartLoading() {
	}
	
	func didFailLoading(error: Error) {
		lossesViewController?.error = error
		killsViewController?.error = error
		viewControllers?.flatMap {($0 as? UITableViewController)?.refreshControl}.filter {$0.isRefreshing}.forEach {
			$0.endRefreshing()
		}
	}
	
	func didFinishLoading() {
		viewControllers?.flatMap {($0 as? UITableViewController)?.refreshControl}.filter {$0.isRefreshing}.forEach {
			$0.endRefreshing()
		}
	}
	
	var managedObjectsObserver: NCManagedObjectObserver?
	lazy var updateGate = NCGate()
	var updateWork: DispatchWorkItem?
	var expireDate: Date?
	
	
	//MARK: - Private
	
	func reloadIfNeeded() {
		if result == nil || (expireDate ?? Date.distantFuture) < Date() {
			reload()
		}
	}
	
	private var isEndReached = false
	private var lastID: Int64?
	
	private var kills: TreeNode?
	private var losses: TreeNode?
	private var result: NCCachedResult<[ESI.Killmails.Recent]>?
	
	private func update(result: NCCachedResult<[ESI.Killmails.Recent]>?, completionHandler: @escaping () -> Void) {
		guard let kills = kills, let losses = losses else {
			isFetching = false
			completionHandler()
			return
		}
		
		
		if let killmails = result?.value, !killmails.isEmpty {
			let partial = Progress(totalUnitCount: Int64(killmails.count))

			var queue = killmails
			let dataManager = self.dataManager
			let characterID = Int(dataManager.characterID)
			
			func pop() {
				if queue.isEmpty {
					if let lastID = killmails.map({$0.killmailID}).min() {
						self.lastID = Int64(lastID)
					}
					self.isFetching = false
					self.fetchIfNeeded()
					completionHandler()
				}
				else {
					let killmail = queue.removeFirst()
					dataManager.killmailInfo(killmailHash: killmail.killmailHash, killmailID: Int64(killmail.killmailID)) { result in
						if let value = result.value {
							UIView.performWithoutAnimation {
								let isLoss = value.victim.characterID == characterID
								
								let node = isLoss ? losses : kills
								let row = NCKillmailRow(killmail: value, characterID: Int64(characterID), dataManager: dataManager)
								
								if let section = node.children.last as? NCDateSection, section.date < value.killmailTime {
									section.children.append(row)
								}
								else {
									let calendar = Calendar(identifier: .gregorian)
									let components = calendar.dateComponents([.year, .month, .day], from: value.killmailTime)
									let date = calendar.date(from: components) ?? value.killmailTime
									let section = NCDateSection(date: date)
									section.children = [row]
									node.children.append(section)
								}
								
								self.lossesViewController?.error = nil
								self.killsViewController?.error = nil
								self.killsViewController?.treeController?.content = kills
								self.lossesViewController?.treeController?.content = losses
							}
						}
						partial.completedUnitCount += 1
						pop()
					}
				}
			}
			
			pop()
		}
		else {
			self.isFetching = false
			self.isEndReached = true
			completionHandler()
		}
	}
	
	private func fetch(from: Int64?, completionHandler: ((NCCachedResult<[ESI.Killmails.Recent]>) -> Void)? = nil) {
		guard !isEndReached, !isFetching else {return}
		isFetching = true
		
		dataManager.killmails(maxKillID: from) { result in
			self.result = result
			self.update(result: result) {
				completionHandler?(result)
			}
		}
	}
}

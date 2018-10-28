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

enum NCKillmailsError: Error {
	case isEndReached
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
		if let page = page, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			guard !isEndReached, !isFetching else {return}

			let progress = NCProgressHandler(viewController: self, totalUnitCount: 1)
			progress.progress.perform {
				fetch(page: page).then { _ in
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
					self?.updateContent()
				}
			}
		}
	}
	
	var isLoading: Bool = false
	lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	
	@discardableResult func updateContent() -> Future<TreeNode?> {
		return content().then(on: .main) { content -> TreeNode? in
			self.killsViewController?.tableView.backgroundView = nil
			self.lossesViewController?.tableView.backgroundView = nil
			return content
		}.catch(on: .main) { error in
			self.killsViewController?.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
			self.lossesViewController?.tableView.backgroundView = NCTableViewBackgroundLabel(text: error.localizedDescription)
		}
	}

	
	func content() -> Future<TreeNode?> {
//		kills = TreeNode()
//		losses = TreeNode()
		return .init(nil)
	}
	
	func load(cachePolicy: URLRequest.CachePolicy) -> Future<[NCCacheRecord]> {
		page = nil
		isEndReached = false
		kills = TreeNode()
		losses = TreeNode()
		self.dataManager = NCDataManager(account: NCAccount.current, cachePolicy: cachePolicy)
		return fetch(page: nil).then(on: .main) { result in
			return [result.cacheRecord(in: NCCache.sharedCache!.viewContext)]
		}
	}
	
	func didStartLoading() {
	}
	
	func didFailLoading(error: Error) {
		lossesViewController?.error = error
		killsViewController?.error = error
		viewControllers?.compactMap {($0 as? UITableViewController)?.refreshControl}.filter {$0.isRefreshing}.forEach {
			$0.endRefreshing()
		}
	}
	
	func didFinishLoading() {
		viewControllers?.compactMap {($0 as? UITableViewController)?.refreshControl}.filter {$0.isRefreshing}.forEach {
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
	private var page: Int?
	
	private var kills = TreeNode()
	private var losses = TreeNode()
	private var result: CachedValue<[ESI.Killmails.Recent]>?
	private var error: Error?
	
	private func update(result: CachedValue<[ESI.Killmails.Recent]>?) -> Future<Void> {
		let promise = Promise<Void>()
		let kills = self.kills
		let losses = self.losses
		
		let totalProgress = Progress(totalUnitCount: 1)
		let dataManager = self.dataManager
		let characterID = Int(dataManager.characterID)

		DispatchQueue.global(qos: .utility).async { () -> Bool in
			guard let killmails = result?.value, !killmails.isEmpty else { return true }
			
			let partialProgress = totalProgress.perform {Progress(totalUnitCount: Int64(killmails.count))}
			
			killmails.forEach { killmail in
				partialProgress.perform {
					dataManager.killmailInfo(killmailHash: killmail.killmailHash, killmailID: Int64(killmail.killmailID)).then(on: .main) { result in
						UIView.performWithoutAnimation {
							guard let value = result.value else {return}
							
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
					}.wait()
				}
			}
			self.page = (self.page ?? 1) + 1
//			if let lastID = killmails.map({$0.killmailID}).min() {
//				self.lastID = Int64(lastID)
//			}

			return false
		}.then(on: .main) { isEndReached in
			self.isEndReached = isEndReached
			self.isFetching = false
			if !isEndReached {
				self.fetchIfNeeded()
			}

		}.finally {
			try! promise.fulfill(())
		}

		return promise.future
	}
	
	private func fetch(page: Int?) -> Future<CachedValue<[ESI.Killmails.Recent]>> {
		let promise = Promise<CachedValue<[ESI.Killmails.Recent]>>()
		guard !isEndReached, !isFetching else {
			try! promise.fail(NCKillmailsError.isEndReached)
			return promise.future
		}
		isFetching = true
		
		dataManager.killmails(page: page).then(on: .main) { result in
			self.result = result
			self.error = nil
			self.update(result: result).finally {
				try! promise.fulfill(result)
			}
		}.catch { error in
			try! promise.fail(error)
		}
		return promise.future
	}
}

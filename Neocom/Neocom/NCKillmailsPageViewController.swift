//
//  NCKillmailsPageViewController.swift
//  Neocom
//
//  Created by Artem Shimanski on 23.06.17.
//  Copyright © 2017 Artem Shimanski. All rights reserved.
//

import UIKit
import EVEAPI

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
		cell.titleLabel?.text = self.title
	}
}


class NCKillmailsPageViewController: NCPageViewController {
	
	var killsViewController: NCKillmailsViewController?
	var lossesViewController: NCKillmailsViewController?
	
	override func viewDidLoad() {
		super.viewDidLoad()

		killsViewController = storyboard!.instantiateViewController(withIdentifier: "NCKillmailsViewController") as? NCKillmailsViewController
		killsViewController?.title = NSLocalizedString("Kills", comment: "")
		lossesViewController = storyboard!.instantiateViewController(withIdentifier: "NCKillmailsViewController") as? NCKillmailsViewController
		lossesViewController?.title = NSLocalizedString("Losses", comment: "")
		
		viewControllers = [killsViewController!, lossesViewController!]
		
		fetch(from: nil)
	}
	
	private(set) var isFetching = false
	
	func fetchIfNeeded() {
		guard let tableView = (currentPage as? NCKillmailsViewController)?.tableView else {return}
		if let lastID = lastID, tableView.contentOffset.y > tableView.contentSize.height - tableView.bounds.size.height * 2 {
			fetch(from: lastID)
		}
		
	}
	
	func reload(cachePolicy: URLRequest.CachePolicy = .useProtocolCachePolicy, completionHandler: (() -> Void)? = nil ) {
		guard let account = NCAccount.current else {
			completionHandler?()
			return
		}
		self.dataManager = NCDataManager(account: account, cachePolicy: cachePolicy)
		isEndReached = false
		lastID = nil
		kills = TreeNode()
		losses = TreeNode()
		fetch(from: nil, completionHandler: completionHandler)
	}
	
	//MARK: - Private
	
	private lazy var dataManager: NCDataManager = NCDataManager(account: NCAccount.current)
	private var isEndReached = false
	private var lastID: Int64?
	
	private var kills = TreeNode()
	private var losses = TreeNode()
	
	private func fetch(from: Int64?, completionHandler: (() -> Void)? = nil) {
		guard !isEndReached, !isFetching else {return}
		let dataManager = self.dataManager
		let characterID = Int(dataManager.characterID)
		isFetching = true
		
		let progress = NCProgressHandler(viewController: self, totalUnitCount: 2)
		
		
		func process(killmails: [ESI.Killmails.Recent]) {
			
			progress.progress.perform {
				let partial = Progress(totalUnitCount: Int64(killmails.count))
				
				if !killmails.isEmpty {
					var queue = killmails
					
					func pop() {
						if queue.isEmpty {
							if let lastID = killmails.map({$0.killmailID}).min() {
								self.lastID = Int64(lastID)
							}
							self.isFetching = false
							self.fetchIfNeeded()
							completionHandler?()
							progress.finish()
						}
						else {
							let killmail = queue.removeFirst()
							dataManager.killmailInfo(killmailHash: killmail.killmailHash, killmailID: Int64(killmail.killmailID)) { result in
								if let value = result.value {
									UIView.performWithoutAnimation {
										let isLoss = value.victim.characterID == characterID
										
										let node = isLoss ? self.losses : self.kills
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
										self.killsViewController?.treeController.content = self.kills
										self.lossesViewController?.treeController.content = self.losses
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
					completionHandler?()
					progress.finish()
				}
			}
		}
		
		progress.progress.perform {
			dataManager.killmails(maxKillID: from) { result in
				switch result {
				case let .success(value, _):
					process(killmails: value)
				case let .failure(error):
					self.isEndReached = true
					self.isFetching = false
					for controller in [self.killsViewController, self.lossesViewController] {
						controller?.error = error
					}
					completionHandler?()
					progress.finish()
				}
			}
		}
	}
}
